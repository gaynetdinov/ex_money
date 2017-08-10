defmodule ExMoney.Web.Api.V2.AccountController do
  use ExMoney.Web, :controller

  alias ExMoney.Account

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.ApiUnauthenticated

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    accounts = Account.by_user_id(user.id) |> Repo.all

    render conn, :index, accounts: accounts
  end
end
