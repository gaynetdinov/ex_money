defmodule ExMoney.Saltedge.AccountController do
  use ExMoney.Web, :controller

  alias ExMoney.SessionController
  alias Guardian.Plug.EnsureAuthenticated
  alias ExMoney.User
  alias ExMoney.Repo
  alias ExMoney.Login
  alias ExMoney.Account

  plug EnsureAuthenticated, %{ on_failure: { SessionController, :new } }

  def sync(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    login = Login.by_user_id(user.id) |> Repo.one

    ExMoney.Saltedge.Account.sync(login.saltedge_login_id)

    redirect(conn, to: "/settings/accounts")
  end
end
