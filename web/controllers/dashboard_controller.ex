defmodule ExMoney.DashboardController do
  use ExMoney.Web, :controller

  alias ExMoney.Login
  alias ExMoney.Repo

  alias ExMoney.SessionController
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, %{ on_failure: { SessionController, :new } }

  def overview(conn, _params) do
    render conn, "overview.html", navigation: "overview"
  end

  def logins(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    logins = Login.by_user_id(user.id) |> Repo.all
    render conn, "logins.html", logins: logins, navigation: "logins"
  end
end
