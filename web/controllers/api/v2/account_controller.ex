defmodule ExMoney.Api.V2.AccountController do
  use ExMoney.Web, :controller

  alias ExMoney.Account

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    accounts = Account.by_user_id(user.id) |> Repo.all

    render conn, :index, accounts: accounts
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(401)
    |> Phoenix.Controller.json(%{errors: ["Authentication required"]})
    |> halt
  end
end
