defmodule ExMoney.Web.Api.V1.SessionController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, User}

  # Standalone web app on iPhone stores token in local storage
  # and every time when it is opened, it sends this token, so
  # Guardian can reauthenticate it.
  def relogin(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        send_resp(conn, 200, "Unauthenticated")
      user ->
        {:ok, claims} = Guardian.Plug.claims(conn)
        jwt = Guardian.Plug.current_token(conn)

        Guardian.revoke!(jwt, claims)

        store_last_login_at(user.last_login_at)
        update_last_login_at(user)

        conn = Guardian.Plug.sign_in(conn, user)
        send_resp(conn, 200, Guardian.Plug.current_token(conn))
    end
  end

  defp update_last_login_at(user) do
    User.update_changeset(user, %{last_login_at: NaiveDateTime.utc_now()})
    |> Repo.update
  end

  defp store_last_login_at(timestamp) do
    case :ets.lookup(:ex_money_cache, "last_login_at") do
      [] -> :ets.insert(:ex_money_cache, {"last_login_at", timestamp})
      _value -> :ets.update_element(:ex_money_cache, "last_login_at", {2, timestamp})
    end
  end
end
