defmodule ExMoney.Web.Callbacks.FailureCallbackController do
  use ExMoney.Web, :controller

  require Logger

  alias ExMoney.{Repo, Login, Web.Plugs}

  plug Plugs.SetUser
  plug Plugs.SetLogin

  def failure(conn, _params) do
    case conn.assigns[:login] do
      nil -> create_login(conn)
      login -> update_login(login, conn)
    end

    put_resp_content_type(conn, "application/json")
    |> send_resp(200, Poison.encode!(%{}))
  end

  defp create_login(conn) do
    login_id = conn.params["data"]["login_id"]
    changeset = Ecto.build_assoc(conn.assigns[:user], :logins)
    |> Login.failure_callback_changeset(%{
      saltedge_login_id: login_id,
      last_fail_error_class: conn.params["data"]["error_class"],
      last_fail_message: conn.params["data"]["error_message"]
    })

    Repo.insert(changeset)
  end

  defp update_login(login, conn) do
    params = %{
      last_fail_error_class: conn.params["data"]["error_class"],
      last_fail_message: conn.params["data"]["error_message"]
    }

    Login.failure_callback_changeset(login, params) |> Repo.update

    interactive_done(conn.assigns[:user].id)
  end

  defp interactive_done(user_id) do
    key = "ongoing_interactive_user:#{user_id}"
    :ets.update_element(:ex_money_cache, key, {2, false})
  end
end
