defmodule ExMoney.Web.SessionController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, User}

  plug :put_layout, "login.html"

  def new(conn, _params) do
    changeset = User.login_changeset(%User{})
    render(conn, ExMoney.Web.SessionView, "new.html", changeset: changeset, topbar: "login")
  end

  def create(conn, params = %{}) do
    user = Repo.one(User.by_email(params["user"]["email"] || ""))
    if user do
      changeset = User.login_changeset(user, params["user"])
      if changeset.valid? do
        update_last_login_at(user)

        Guardian.Plug.sign_in(conn, user)
        |> redirect(to: dashboard_path(conn, :overview))
      else
        render(conn, :new, changeset: changeset)
      end
    else
      changeset = User.login_changeset(%User{})
      |> Ecto.Changeset.add_error(:login, "not found")
      render(conn, :new, changeset: changeset)
    end
  end

  def delete(conn, _params) do
    if {:ok, claims} = Guardian.Plug.claims(conn) do
      jwt = Guardian.Plug.current_token(conn)
      Guardian.revoke!(jwt, claims)
    end

    Guardian.Plug.sign_out(conn)
    |> redirect(to: "/login")
  end

  defp update_last_login_at(user) do
    User.update_changeset(user, %{last_login_at: NaiveDateTime.utc_now()})
    |> Repo.update
  end
end
