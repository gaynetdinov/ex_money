defmodule ExMoney.Mobile.TransactionController do
  use ExMoney.Web, :controller
  alias ExMoney.{Repo, Transaction, Category, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def new(conn, _params) do
    categories = Category.select_list
    |> Repo.all
    |> Enum.reduce([], fn({name, id}, acc) ->
      humanized_name = String.replace(name, "_", " ") |> String.capitalize
      [{humanized_name, id} | acc]
    end)

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

  def create(conn, %{"transaction" => transaction_params}) do
    user = Guardian.Plug.current_resource(conn)
    transaction_params = Map.put(transaction_params, "user_id", user.id)
    changeset = Transaction.changeset_custom(%Transaction{}, transaction_params)

    case Repo.insert(changeset) do
      {:ok, _transaction} ->
        send_resp(conn, 200, "")
      {:error, _changeset} ->
        send_resp(conn, 422, "Something went wrong, check server logs")
    end
  end

  def expenses(conn, params) do
    parsed_date = parse_date(params["date"])
    from = first_day_of_month(parsed_date)
    to = last_day_of_month(parsed_date)

    expenses = Transaction.expenses_by_month(from, to)
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    {:ok, date} = Timex.DateFormat.format(parsed_date, "%b %Y", :strftime)

    render conn, :expenses,
      expenses: expenses,
      date: date
  end

  def income(conn, params) do
    parsed_date = parse_date(params["date"])
    from = first_day_of_month(parsed_date)
    to = last_day_of_month(parsed_date)

    income = Transaction.income_by_month(from, to)
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    {:ok, date} = Timex.DateFormat.format(parsed_date, "%b %Y", :strftime)

    render conn, :income,
      income: income,
      date: date
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
