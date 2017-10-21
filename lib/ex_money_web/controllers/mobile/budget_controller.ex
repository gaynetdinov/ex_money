defmodule ExMoney.Web.Mobile.BudgetController do
  use ExMoney.Web, :controller

  alias ExMoney.DateHelper
  alias ExMoney.{Repo, Transaction, Budget}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    current_budget = Budget.current_by_user_id(user.id) |> Repo.one

    if current_budget do
      _index(conn, params, current_budget)
    else
      render conn, :setup
    end
  end

  defp _index(conn, params, current_budget) do
    parsed_date = DateHelper.parse_date(params["date"])
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    account_ids = current_budget.accounts
    month_transactions = Transaction.by_month(account_ids, from, to)
    |> Repo.all

    categories = Transaction.group_by_month_by_category_without_withdraw(account_ids, from, to)
    |> Repo.all

    current_month = DateHelper.current_month(parsed_date)
    previous_month = DateHelper.previous_month(parsed_date)
    next_month = DateHelper.next_month(parsed_date)

    currency_label = if month_transactions != [] do
      List.first(month_transactions).account.currency_label
    else
      ""
    end

    categories_limits = Enum.reduce current_budget.items, %{}, fn({item_id, limit}, acc) ->
      {item_id, _} = Integer.parse(item_id)
      {limit, _} = Integer.parse(limit)
      Map.put(acc, item_id, limit)
    end

    render conn, :index,
      month_transactions: month_transactions,
      categories_limits: categories_limits,
      currency_label: currency_label,
      categories: categories,
      current_month: current_month,
      previous_month: previous_month,
      next_month: next_month
  end

  def expenses(conn, %{"date" => date}) do
    user = Guardian.Plug.current_resource(conn)
    current_budget = Budget.current_by_user_id(user.id) |> Repo.one
    parsed_date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    scope = Transaction.expenses_by_month(current_budget.accounts, from, to)
    expenses = fetch_and_process_transactions(scope)

    {:ok, formatted_date} = Timex.format(parsed_date, "%b %Y", :strftime)

    from = URI.encode_www_form("/m/budget/expenses?date=#{date}")

    render conn, :expenses,
      expenses: expenses,
      date: %{label: formatted_date, value: date},
      from: from
  end

  def income(conn, %{"date" => date}) do
    user = Guardian.Plug.current_resource(conn)
    current_budget = Budget.current_by_user_id(user.id) |> Repo.one
    parsed_date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    scope = Transaction.income_by_month(current_budget.accounts, from, to)
    income = fetch_and_process_transactions(scope)

    {:ok, formatted_date} = Timex.format(parsed_date, "%b %Y", :strftime)

    from = URI.encode_www_form("/m/budget/income?date=#{date}")

    render conn, :income,
      income: income,
      date: %{label: formatted_date, value: date},
      from: from
  end

  defp fetch_and_process_transactions(scope) do
    scope
    |> Repo.all
    |> Enum.group_by(fn(transaction) -> transaction.made_on end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Date.compare(date_1, date_2) != :lt
    end)
  end
end
