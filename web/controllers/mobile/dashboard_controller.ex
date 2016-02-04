defmodule ExMoney.Mobile.DashboardController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Transaction, User, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def overview(conn, _params) do
    recent_transactions = Transaction.recent
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    accounts = Account.show_on_dashboard |> Repo.all

    render conn, :overview,
      recent_transactions: recent_transactions,
      accounts: accounts
  end

  defp parse_date(month) when month == "" or is_nil(month) do
    current_date()
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

  defp current_date() do
    Timex.Date.local
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
end
