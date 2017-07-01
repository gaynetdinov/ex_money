defmodule ExMoney.Mobile.BudgetController do
  use ExMoney.Web, :controller

  alias ExMoney.DateHelper
  alias ExMoney.{Repo, Transaction, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def index(conn, params) do
    accounts = Account.in_budget |> Repo.all

    _index(conn, params, accounts)
  end

  defp _index(conn, _, []) do
    render conn, :setup
  end

  defp _index(conn, params, accounts) do
    parsed_date = DateHelper.parse_date(params["date"])
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    account_ids = Enum.map(accounts, fn(acc) -> acc.id end)
    month_transactions = Transaction.by_month(account_ids, from, to)
    |> Repo.all

    categories = Transaction.group_by_month_by_category_without_withdraw(account_ids, from, to)
    |> Repo.all
    |> Enum.reduce(%{}, fn({category, amount}, acc) ->
      {float_amount, _} = Decimal.to_string(amount, :normal)
      |> Float.parse

      positive_float = float_amount * -1

      Map.put(acc, category.id,
        %{
          id: category.id,
          humanized_name: category.humanized_name,
          css_color: category.css_color,
          amount: positive_float,
          parent_id: category.parent_id
        })
    end)

    current_month = DateHelper.current_month(parsed_date)
    previous_month = DateHelper.previous_month(parsed_date)
    next_month = DateHelper.next_month(parsed_date)

    currency_label = if month_transactions != [] do
      List.first(month_transactions).account.currency_label
    else
      ""
    end

    render conn, :index,
      month_transactions: month_transactions,
      currency_label: currency_label,
      categories: categories,
      current_month: current_month,
      previous_month: previous_month,
      next_month: next_month
  end

  def expenses(conn, %{"date" => date}) do
    parsed_date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    budget_account_ids = Account.in_budget
    |> Repo.all
    |> Enum.map(fn(acc) -> acc.id end)

    scope = Transaction.expenses_by_month(budget_account_ids, from, to)
    expenses = fetch_and_process_transactions(scope)

    {:ok, formatted_date} = Timex.format(parsed_date, "%b %Y", :strftime)

    from = URI.encode_www_form("/m/budget/expenses?date=#{date}")

    render conn, :expenses,
      expenses: expenses,
      date: %{label: formatted_date, value: date},
      from: from
  end

  def income(conn, %{"date" => date}) do
    parsed_date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    budget_account_ids = Account.in_budget
    |> Repo.all
    |> Enum.map(fn(acc) -> acc.id end)

    scope = Transaction.income_by_month(budget_account_ids, from, to)
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
