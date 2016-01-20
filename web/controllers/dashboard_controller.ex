defmodule ExMoney.DashboardController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Transaction, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated

  def overview(conn, _params) do
    recent_transactions = Transaction.recent
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    from = Timex.Date.local |> first_day_of_month
    to = Timex.Date.local |> last_day_of_month
    last_month_transactions = Transaction.by_month(from, to)
    |> Repo.all

    accounts = Account.show_on_dashboard
    |> Repo.all

    render conn, "overview.html",
      navigation: "overview",
      topbar: "dashboard",
      recent_transactions: recent_transactions,
      last_month_transactions: last_month_transactions,
      accounts: accounts
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
