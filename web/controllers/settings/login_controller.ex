defmodule ExMoney.Settings.LoginController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Login, LoginLog, Paginator}
  import Ecto.Query

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    logins = Login.by_user_id(user.id) |> Repo.all

    render conn, :index,
      logins: logins,
      navigation: "logins",
      topbar: "settings"
  end

  def show(conn, %{"id" => id} = params) do
    login = Repo.get!(Login, id)

    paginator = LoginLog.by_login_id(id)
    |> order_by(desc: :inserted_at)
    |> Paginator.paginate(params)

    render conn, :show,
      navigation: "logins",
      topbar: "settings",
      login: login,
      logs: paginator.entries,
      page_number: paginator.page_number,
      total_pages: paginator.total_pages
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
