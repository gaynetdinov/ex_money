defmodule ExMoney.Web.Settings.UserController do
  use ExMoney.Web, :controller

  alias ExMoney.User

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated
  plug :scrub_params, "user" when action in [:create, :update]

  def edit(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    changeset = User.update_changeset(user)

    render conn, :edit,
      user: user,
      changeset: changeset,
      navigation: "account",
      topbar: "settings"
  end

  def update(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.update_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: settings_user_path(conn, :edit))
      {:error, changeset} ->
        render conn, :edit,
          user: user,
          changeset: changeset,
          navigation: "account",
          topbar: "settings"
    end
  end
end
