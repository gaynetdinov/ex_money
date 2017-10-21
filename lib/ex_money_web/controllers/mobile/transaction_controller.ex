defmodule ExMoney.Web.Mobile.TransactionController do
  use ExMoney.Web, :controller

  alias ExMoney.DateHelper
  alias ExMoney.{Repo, Transaction, Category, Account, FavouriteTransaction, Budget}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def index(conn, %{"date" => date, "account_id" => account_id, "category_id" => category_id}) do
    account = Repo.get!(Account, account_id)
    category = Repo.get!(Category, category_id)
    category_ids = case category.parent_id do
      nil -> [category.id | Repo.all(Category.sub_categories_by_id(category.id))]
      _parent_id -> [category.id]
    end

    parsed_date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    transactions = Transaction.by_month_by_category(account_id, from, to, category_ids)
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Date.compare(date_1, date_2) != :lt
    end)

    {:ok, formatted_date} = Timex.format(parsed_date, "%b %Y", :strftime)

    from = case transactions do
      [] -> "/m/accounts/#{account_id}"
      _ -> "/m/transactions?date=#{date}&category_id=#{category_id}&account_id=#{account_id}"
    end |> URI.encode_www_form

    render conn, :index,
      transactions: transactions,
      date: %{label: formatted_date, value: date},
      category: category.humanized_name,
      from: from,
      slug: "accounts/#{account.id}"
  end

  def index(conn, %{"date" => date, "category_id" => category_id, "type" => type}) do
    user = Guardian.Plug.current_resource(conn)
    current_budget = Budget.current_by_user_id(user.id) |> Repo.one

    category = Repo.get!(Category, category_id)
    category_ids = case category.parent_id do
      nil -> [category.id | Repo.all(Category.sub_categories_by_id(category.id))]
      _parent_id -> [category.id]
    end

    parsed_date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    query = case type do
      "expenses" ->
        Transaction.expenses_by_month_by_category(current_budget.accounts, from, to, category_ids)
      "income" ->
        Transaction.income_by_month_by_category(current_budget.accounts, from, to, category_ids)
    end

    transactions = query
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Date.compare(date_1, date_2) != :lt
    end)

    {:ok, formatted_date} = Timex.format(parsed_date, "%b %Y", :strftime)

    from = URI.encode_www_form("/m/budget?date=#{date}")

    render conn, :index,
      transactions: transactions,
      date: %{label: formatted_date, value: date},
      category: category.humanized_name,
      from: from,
      slug: "budget"
  end

  def new(conn, _params) do
    categories = categories_list()
    uncategorized = Map.keys(categories)
    |> Enum.find(fn({name, _id}) -> name == "Uncategorized" end)
    categories = Map.delete(categories, uncategorized)
    categories = [{uncategorized, []} | Map.to_list(categories)]

    accounts = Account.only_custom |> Repo.all

    changeset = Transaction.changeset_custom(%Transaction{})

    render conn, :new,
      categories: categories,
      changeset: changeset,
      accounts: accounts
  end

  def edit(conn, %{"id" => id, "from" => from}) do
    transaction = Repo.get(Transaction, id)
    categories = categories_list()
    changeset = Transaction.update_changeset(transaction)

    render conn, :edit,
      transaction: transaction,
      categories: categories,
      changeset: changeset,
      from: from
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = Repo.get!(Transaction, id)

    from = validate_from_param(transaction_params["from"])

    changeset = Transaction.update_changeset(transaction, transaction_params)

    case Repo.update(changeset) do
      {:ok, _transaction} ->
        send_resp(conn, 200, from)
      {:error, _changeset} ->
        send_resp(conn, 422, "Something went wrong, check server logs")
    end
  end

  def create(conn, %{"transaction" => transaction_params}) do
    user = Guardian.Plug.current_resource(conn)
    transaction_params = Map.put(transaction_params, "user_id", user.id)
    changeset = Transaction.changeset_custom(%Transaction{}, transaction_params)

    Repo.transaction fn ->
      transaction = Repo.insert!(changeset)
      account = Repo.get!(Account, transaction.account_id)
      new_balance = Decimal.add(account.balance, transaction.amount)
      Account.update_custom_changeset(account, %{balance: new_balance})
      |> Repo.update!
    end

    send_resp(conn, 200, "")
  end

  def create_from_fav(conn, %{"transaction[amount]" => ""}) do
    send_resp(conn, 200, "")
  end

  def create_from_fav(conn, params) do
    amount =  params["transaction[amount]"]
    fav_tr_id = params["transaction[fav_tr_id]"]
    fav_tr = Repo.get!(FavouriteTransaction, fav_tr_id)

    {:ok, made_on} = Date.from_erl(DateHelper.today)
    transaction_params = %{
      "amount" => amount,
      "user_id" => fav_tr.user_id,
      "category_id" => fav_tr.category_id,
      "account_id" => fav_tr.account_id,
      "made_on" => made_on,
      "type" => "expense"
    }
    changeset = Transaction.changeset_custom(%Transaction{}, transaction_params)

    Repo.transaction fn ->
      transaction = Repo.insert!(changeset)
      account = Repo.get!(Account, transaction.account_id)
      new_balance = Decimal.add(account.balance, transaction.amount)
      Account.update_custom_changeset(account, %{balance: new_balance})
      |> Repo.update!
    end

    send_resp(conn, 200, "")
  end

  def show(conn, %{"id" => id}) do
    transaction = Repo.one(
      from tr in Transaction,
        where: tr.id == ^id,
        preload: [:account, :category]
      )

    render conn, :show, transaction: transaction
  end

  def delete(conn, %{"id" => id}) do
    transaction = Repo.get!(Transaction, id)
    account = Repo.get!(Account, transaction.account_id)

    case transaction.saltedge_transaction_id do
      nil ->
        new_balance = Decimal.sub(account.balance, transaction.amount)

        Repo.transaction(fn ->
          Repo.delete!(transaction)

          Account.update_custom_changeset(account, %{balance: new_balance})
          |> Repo.update!
        end)

        render conn, :delete,
          account_id: account.id,
          new_balance: new_balance
      _ ->
        Repo.transaction(fn ->
          Repo.delete!(transaction)
        end)

        body = """
          { "data": [{ "transaction_id": #{transaction.saltedge_transaction_id} }]}
        """

        {:ok, _} = ExMoney.Saltedge.Client.request(:put, "transactions/duplicate", body)

        render conn, :delete, new_balance: false
    end
  end

  defp categories_list do
    categories_dict = Category.visible |> Repo.all

    Enum.reduce(categories_dict, %{}, fn(category, acc) ->
      if is_nil(category.parent_id) do
        sub_categories = Enum.filter(categories_dict, fn(c) -> c.parent_id == category.id end)
        |> Enum.map(fn(sub_category) -> {sub_category.humanized_name, sub_category.id} end)
        Map.put(acc, {category.humanized_name, category.id}, sub_categories)
      else
        acc
      end
    end)
  end

  # FIXME: that looks terrible, I'm really sorry.
  defp validate_from_param(from) do
    if String.match?(from, ~r/\A\/m\/accounts\/\d+\/(expenses|income)\?date=\d{4}-\d{1,2}\z/) or
      String.match?(from, ~r/\A\/m\/transactions\?date=\d{4}-\d{1,2}\&category_id=\d+\&account_id=\d+\z/) or
      String.match?(from, ~r/\A\/m\/accounts\/\d+\z/) or
      String.match?(from, ~r/\A\/m\/budget\?date=\d{4}-\d{1,2}\z/) do

      from
    else
      "/m/dashboard"
    end
  end
end
