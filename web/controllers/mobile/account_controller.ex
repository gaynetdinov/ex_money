defmodule ExMoney.Mobile.AccountController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Transaction, Account, AccountsBalanceHistory}

  import Ecto.Query

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def show(conn, %{"id" => account_id} = params) do
    parsed_date = parse_date(params["date"])
    from = first_day_of_month(parsed_date)
    to = last_day_of_month(parsed_date)

    account = Account
    |> where([a], a.id == ^account_id)
    |> preload(:login)
    |> Repo.one

    month_transactions = Transaction.by_month(account_id, from, to)
    |> Repo.all

    categories = Transaction.group_by_month_by_category(account_id, from, to)
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

    current_month = current_month(parsed_date)
    previous_month = previous_month(parsed_date)
    next_month = next_month(parsed_date)

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
    parsed_date = parse_date(date)
    from = first_day_of_month(parsed_date)
    to = last_day_of_month(parsed_date)
    account_balance = account_balance(from, to, account.id)

    expenses = Transaction.expenses_by_month(account_id, from, to)
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    {:ok, formatted_date} = Timex.DateFormat.format(parsed_date, "%b %Y", :strftime)

    from = URI.encode_www_form("/m/accounts/#{account_id}/expenses?date=#{date}")

    render conn, :expenses,
      currency_label: account.currency_label,
      expenses: expenses,
      date: %{label: formatted_date, value: date},
      from: from,
      account: account,
      account_balance: account_balance
  end

  def income(conn, %{"date" => date, "id" => account_id}) do
    account = Repo.get!(Account, account_id)
    parsed_date = parse_date(date)
    from = first_day_of_month(parsed_date)
    to = last_day_of_month(parsed_date)
    account_balance = account_balance(from, to, account.id)

    income = Transaction.income_by_month(account_id, from, to)
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    {:ok, formatted_date} = Timex.DateFormat.format(parsed_date, "%b %Y", :strftime)

    from = URI.encode_www_form("/m/accounts/#{account_id}/income?date=#{date}")

    render conn, :income,
      currency_label: account.currency_label,
      income: income,
      date: %{label: formatted_date, value: date},
      from: from,
      account: account,
      account_balance: account_balance
  end

  defp parse_date(month) when month == "" or is_nil(month) do
    Timex.Date.local
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

  defp current_month(date) do
    {:ok, current_month} = Timex.DateFormat.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.DateFormat.format(date, "%b %Y", :strftime)

    %{date: current_month, label: label}
  end

  defp next_month(date) do
    date = Timex.Date.shift(date, months: 1)

    {:ok, next_month} = Timex.DateFormat.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.DateFormat.format(date, "%b %Y", :strftime)

    %{date: next_month, label: label}
  end

  defp previous_month(date) do
    date = Timex.Date.shift(date, months: -1)

    {:ok, previous_month} = Timex.DateFormat.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.DateFormat.format(date, "%b %Y", :strftime)

    %{date: previous_month, label: label}
  end

  defp account_balance(from, to, account_id) do
    AccountsBalanceHistory.history(from, to, account_id)
    |> Repo.all
    |> Enum.reduce(%{}, fn(h, acc) ->
      {:ok, {inserted_at, _}} = Ecto.DateTime.dump(h.inserted_at)

      d = Timex.Date.from({inserted_at, {0, 0, 0}})
      |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
      |> elem(1)

      Map.put(acc, d, h.balance)
    end)
  end
end
