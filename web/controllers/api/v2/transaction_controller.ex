defmodule ExMoney.Api.V2.TransactionController do
  use ExMoney.Web, :controller

  alias ExMoney.Transaction

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  def recent(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    transactions = Transaction.recent(user.id) |> Repo.all

    render conn, :recent, transactions: transactions
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(401)
    |> Phoenix.Controller.json(%{errors: ["Authentication required"]})
    |> halt
  end
end
