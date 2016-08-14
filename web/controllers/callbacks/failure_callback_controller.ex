defmodule ExMoney.Callbacks.FailureCallbackController do
  use ExMoney.Web, :controller

  @login_logger Application.get_env(:ex_money, :login_logger_worker)

  require Logger

  alias ExMoney.{Repo, Login, Plugs}

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

    case Repo.insert(changeset) do
      {:ok, login} ->
        @login_logger.log_event("failure", "login_created", login.saltedge_login_id, params)
      {:error, changeset} ->
        @login_logger.log_event("failure", "login_create_failed", login_id, Enum.into(changeset.errors, %{}))
    end
  end

  defp update_login(login, conn) do
    params = %{
      last_fail_error_class: conn.params["data"]["error_class"],
      last_fail_message: conn.params["data"]["error_message"]
    }

    changeset = Login.failure_callback_changeset(login, params)
    case Repo.update(changeset) do
      {:ok, _} -> @login_logger.log_event("failure", "login_create_failed", login_id, params)
      {:error, changeset} -> @login_logger.log_event("failure", "login_create_failed", login_id, Enum.into(changeset.errors, %{}))
    end

    interactive_done(conn.assigns[:user].id)
  end

  defp interactive_done(user_id) do
    key = "ongoing_interactive_user:#{user_id}"
    :ets.update_element(:ex_money_cache, key, {2, false})
  end
end
