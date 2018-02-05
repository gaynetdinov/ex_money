defmodule ExMoney.Web.Settings.LoginController do
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

  def delete(conn, %{"id" => id}) do
    login = Repo.get!(Login, id)

    Repo.delete!(login)

    {:ok, _} = ExMoney.Saltedge.Client.request(:delete, "logins/#{login.saltedge_login_id}")

    conn
    |> put_flash(:info, "Login deleted successfully.")
    |> redirect(to: settings_login_path(conn, :index))
  end
end
