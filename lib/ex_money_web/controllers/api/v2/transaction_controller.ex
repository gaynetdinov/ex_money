defmodule ExMoney.Web.Api.V2.TransactionController do
  use ExMoney.Web, :controller

  alias ExMoney.Transactions

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.ApiUnauthenticated

  def recent(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    transactions = Transactions.recent(user.id)

    render conn, :recent, transactions: transactions
  end
end
