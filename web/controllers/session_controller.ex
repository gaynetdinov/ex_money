defmodule ExMoney.SessionController do
  use ExMoney.Web, :controller

  alias ExMoney.User
  alias ExMoney.Repo

  def new(conn, params) do
    changeset = User.login_changeset(%User{})
    render(conn, ExMoney.SessionView, "new.html", changeset: changeset)
  end

  def create(conn, params = %{}) do
    user = Repo.one(User.by_email(params["user"]["email"] || ""))
    if user do
      changeset = User.login_changeset(user, params["user"])
      if changeset.valid? do
        conn
        |> put_flash(:info, "Logged in.")
        |> Guardian.Plug.sign_in(user, :token)
        |> redirect(to: user_path(conn, :index))
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
    |> redirect(to: "/")
  end
end
