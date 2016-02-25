defmodule ExMoney.Settings.LoginController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Login}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    logins = Login.by_user_id(user.id) |> Repo.all

    render conn, :index,
      logins: logins,
      navigation: "logins",
      topbar: "settings"
  end
end
