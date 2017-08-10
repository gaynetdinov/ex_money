defmodule ExMoney.Web.DashboardController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Transaction, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated

  def overview(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    recent_transactions = Transaction.recent(user.id)
    |> Repo.all
    |> Enum.group_by(fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Date.compare(date_1, date_2) != :lt
    end)

    accounts = Account.show_on_dashboard
    |> Repo.all

    render conn, :overview,
      navigation: "overview",
      topbar: "dashboard",
      recent_transactions: recent_transactions,
      accounts: accounts
  end
end
