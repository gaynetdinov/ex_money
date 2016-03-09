defmodule ExMoney.Mobile.TransactionController do
  use ExMoney.Web, :controller
  alias ExMoney.{Repo, Transaction, Category, Account, TransactionInfo}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def new(conn, _params) do
    categories = Category.select_list
    |> Repo.all

    uncategorized = Enum.find(categories, fn({name, _id}) -> name == "Uncategorized" end)
    sorted_categories = Enum.sort(categories, fn({name_1, _id_1}, {name_2, _id_2}) ->
      name_2 > name_1
    end)

    categories = List.flatten([uncategorized | sorted_categories])
    accounts = Account.only_custom |> Repo.all

    changeset = Transaction.changeset_custom(%Transaction{})

    render conn, :new,
      categories: categories,
      changeset: changeset,
      accounts: accounts
  end

  def edit(conn, %{"id" => id}) do
    transaction = Repo.get(Transaction, id)

    categories_dict = Repo.all(Category)

    categories = Enum.reduce(categories_dict, %{}, fn(category, acc) ->
      if is_nil(category.parent_id) do
        sub_categories = Enum.filter(categories_dict, fn(c) -> c.parent_id == category.id end)
        |> Enum.map(fn(sub_category) -> {sub_category.humanized_name, sub_category.id} end)
        Map.put(acc, {category.humanized_name, category.id}, sub_categories)
      else
        acc
      end
    end)

    changeset = Transaction.update_changeset(transaction)

    render conn, :edit,
      transaction: transaction,
      categories: categories,
      changeset: changeset
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = Repo.get!(Transaction, id)

    changeset = Transaction.update_changeset(transaction, transaction_params)

    case Repo.update(changeset) do
      {:ok, _transaction} ->
        send_resp(conn, 200, "")
      {:error, _changeset} ->
        send_resp(conn, 422, "Something went wrong, check server logs")
    end
  end

  def create(conn, %{"transaction" => transaction_params}) do
    user = Guardian.Plug.current_resource(conn)
    transaction_params = Map.put(transaction_params, "user_id", user.id)
    changeset = Transaction.changeset_custom(%Transaction{}, transaction_params)

    Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, transaction} ->
          account = Repo.get!(Account, transaction.account_id)
          new_balance = Decimal.add(account.balance, transaction.amount)
          Account.update_custom_changeset(account, %{balance: new_balance})
          |> Repo.update!

          send_resp(conn, 200, "")
        {:error, _changeset} ->
          send_resp(conn, 422, "Something went wrong, check server logs")
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    transaction = Repo.one(
      from tr in Transaction,
        where: tr.id == ^id,
        preload: [:account, :transaction_info, :category]
      )
    render(conn, :show, transaction: transaction)
  end

  def expenses(conn, %{"date" => date, "account_id" => account_id}) do
    account = Repo.get!(Account, account_id)
    parsed_date = parse_date(date)
    from = first_day_of_month(parsed_date)
    to = last_day_of_month(parsed_date)

    expenses = Transaction.expenses_by_month(account_id, from, to)
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    {:ok, date} = Timex.DateFormat.format(parsed_date, "%b %Y", :strftime)

    render conn, :expenses,
      currency_label: account.currency_label,
      expenses: expenses,
      date: date
  end

  def income(conn, %{"date" => date, "account_id" => account_id}) do
    account = Repo.get!(Account, account_id)
    parsed_date = parse_date(date)
    from = first_day_of_month(parsed_date)
    to = last_day_of_month(parsed_date)

    income = Transaction.income_by_month(account_id, from, to)
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    {:ok, date} = Timex.DateFormat.format(parsed_date, "%b %Y", :strftime)

    render conn, :income,
      currency_label: account.currency_label,
      income: income,
      date: date
  end

  def delete(conn, %{"id" => id}) do
    transaction = Repo.get!(Transaction, id)
    account = Repo.get!(Account, transaction.account_id)
    new_balance = Decimal.sub(account.balance, transaction.amount)

    Repo.transaction(fn ->
      tr_info = TransactionInfo.by_transaction_id(id) |> Repo.one
      if tr_info, do: Repo.delete!(tr_info)

      Repo.delete!(transaction)

      Account.update_custom_changeset(account, %{balance: new_balance})
      |> Repo.update!
    end)

    render conn, :delete,
      account_id: account.id,
      new_balance: new_balance
  end

  defp parse_date(month) do
    {:ok, date} = Timex.DateFormat.parse(month, "{YYYY}-{0M}")
    date
  end

  defp first_day_of_month(date) do
    Timex.Date.from({{date.year, date.month, 0}, {0, 0, 0}})
    |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
    |> elem(1)
  end

  defp last_day_of_month(date) do
    days_in_month = Timex.Date.days_in_month(date)

    Timex.Date.from({{date.year, date.month, days_in_month}, {23, 59, 59}})
    |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
    |> elem(1)
  end
end
