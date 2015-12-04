defmodule ExMoney.SettingsController do
  use ExMoney.Web, :controller

  alias ExMoney.SessionController
  alias Guardian.Plug.EnsureAuthenticated
  alias ExMoney.Login
  alias ExMoney.Repo

  plug EnsureAuthenticated, %{ on_failure: { SessionController, :new } }

  def logins(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    logins = Login.by_user_id(user.id) |> Repo.all
    render conn, "logins.html", logins: logins, navigation: "logins", topbar: "settings"
  end
end
