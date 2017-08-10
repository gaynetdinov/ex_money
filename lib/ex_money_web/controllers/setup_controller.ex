defmodule ExMoney.Web.SetupController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, User}

  plug :put_layout, "setup.html"

  def new(conn, _params) do
    changeset = User.create_changeset(%User{})
    render(conn, :setup, changeset: changeset)
  end

  def complete(conn, params = %{}) do
    changeset = User.create_changeset(%User{}, params["user"])
    if changeset.valid? do
      user = Repo.insert!(changeset)

      conn
      |> Guardian.Plug.sign_in(user)
      |> redirect(to: dashboard_path(conn, :overview))
    else
      render(conn, :setup, changeset: changeset)
    end
  end
end
