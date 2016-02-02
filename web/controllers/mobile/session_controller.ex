defmodule ExMoney.Mobile.SessionController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, User}

  plug :put_layout, "mobile.html"

  def new(conn, _params) do
    changeset = User.login_changeset(%User{})
    render(conn, ExMoney.Mobile.SessionView, :new, changeset: changeset)
  end

  def create(conn, params = %{}) do
    user = Repo.one(User.by_email(params["user"]["email"] || ""))
    if user do
      changeset = User.login_changeset(user, params["user"])
      if changeset.valid? do
        conn
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: mobile_dashboard_path(conn, :index))
      else
        send_resp(conn, 401, "Unauthenticated")
      end
    else
      send_resp(conn, 401, "Unauthenticated")
    end
  end

  def delete(conn, _params) do
    Guardian.Plug.sign_out(conn)
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: "/login")
  end
end
