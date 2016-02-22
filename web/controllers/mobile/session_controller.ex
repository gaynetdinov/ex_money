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
        store_last_login_at(user.last_login_at)
        update_last_login_at(user)

        conn = Guardian.Plug.sign_in(conn, user)
        send_resp(conn, 200, Guardian.Plug.current_token(conn))
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

  defp update_last_login_at(user) do
    User.update_changeset(user, %{last_login_at: :calendar.universal_time})
    |> Repo.update
  end

  defp store_last_login_at(timestamp) do
    case :ets.lookup(:ex_money_cache, "last_login_at") do
      [] -> :ets.insert(:ex_money_cache, {"last_login_at", timestamp})
      _value -> :ets.update_element(:ex_money_cache, "last_login_at", {2, timestamp})
    end
  end
end
