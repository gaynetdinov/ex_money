defmodule ExMoney.SessionController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, User}

  plug :put_layout, "login.html"

  def new(conn, _params) do
    changeset = User.login_changeset(%User{})
    render(conn, ExMoney.SessionView, "new.html", changeset: changeset, topbar: "login")
  end

  def create(conn, params = %{}) do
    user = Repo.one(User.by_email(params["user"]["email"] || ""))
    if user do
      changeset = User.login_changeset(user, params["user"])
      if changeset.valid? do
        update_last_login_at(user)

        conn
        |> put_flash(:info, "Logged in.")
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: dashboard_path(conn, :overview))
      else
        render(conn, "new.html", changeset: changeset)
      end
    else
      changeset = User.login_changeset(%User{}) |> Ecto.Changeset.add_error(:login, "not found")
      render(conn, "new.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    Guardian.Plug.sign_out(conn)
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: "/login")
  end

  defp update_last_login_at(user) do
    User.update_changeset(user, %{last_login_at: :calendar.local_time})
    |> Repo.update
  end
end
