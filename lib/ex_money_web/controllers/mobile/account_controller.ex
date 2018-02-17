defmodule ExMoney.Web.Mobile.AccountController do
  use ExMoney.Web, :controller

  alias ExMoney.DateHelper
  alias ExMoney.{Repo, Transactions, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def show(conn, %{"id" => account_id} = params) do
    parsed_date = DateHelper.parse_date(params["date"])
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)

    account = Account.by_id_with_login(account_id) |> Repo.one

    month_transactions = Transactions.by_month(account_id, from, to) |> Repo.all()

    categories = Transactions.group_by_month_by_category(account_id, from, to)
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

    render conn, :show,
      account: account,
      month_transactions: month_transactions,
      categories: categories,
      current_month: current_month,
      previous_month: previous_month,
      next_month: next_month
  end

  def refresh(conn, %{"id" => account_id}) do
    account = Repo.get(Account, account_id)

    render conn, :refresh, account: account
  end

  def expenses(conn, %{"date" => date, "id" => account_id}) do
    account = Repo.get!(Account, account_id)
    parsed_date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)
    account_balance = account_balance(from, to, account.id)

    transactions = Transactions.expenses_by_month(account_id, from, to)
    expenses = process_transactions(transactions)

    {:ok, formatted_date} = Timex.format(parsed_date, "%b %Y", :strftime)

    from = URI.encode_www_form("/m/accounts/#{account_id}/expenses?date=#{date}")

    render conn, :expenses,
      expenses: expenses,
      date: %{label: formatted_date, value: date},
      from: from,
      account: account,
      account_balance: account_balance
  end

  def income(conn, %{"date" => date, "id" => account_id}) do
    account = Repo.get!(Account, account_id)
    parsed_date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(parsed_date)
    to = DateHelper.last_day_of_month(parsed_date)
    account_balance = account_balance(from, to, account.id)

    transactions = Transactions.income_by_month(account_id, from, to)
    income = process_transactions(transactions)

    {:ok, formatted_date} = Timex.format(parsed_date, "%b %Y", :strftime)

    from = URI.encode_www_form("/m/accounts/#{account_id}/income?date=#{date}")

    render conn, :income,
      income: income,
      date: %{label: formatted_date, value: date},
      from: from,
      account: account,
      account_balance: account_balance
  end

  defp account_balance(from, to, account_id) do
    ExMoney.Accounts.get_account_history_balance(from, to)
    |> Enum.reduce(%{}, fn(history, acc) ->
      inserted_at =
        history.inserted_at
        |> NaiveDateTime.to_date()
        |> Date.to_string()

      Map.put(acc, inserted_at, history.state[to_string(account_id)])
    end)
  end

  defp process_transactions(transactions) do
    transactions
    |> Enum.group_by(fn(transaction) -> transaction.made_on end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Date.compare(date_1, date_2) != :lt
    end)
  end
end
