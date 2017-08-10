defmodule ExMoney.Web.Api.V2.TransactionController do
  use ExMoney.Web, :controller

  alias ExMoney.Transaction

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.ApiUnauthenticated

  def recent(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    transactions = Transaction.recent(user.id) |> Repo.all

    render conn, :recent, transactions: transactions
  end
end
