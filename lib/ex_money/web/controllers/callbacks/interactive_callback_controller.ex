defmodule ExMoney.Web.Callbacks.InteractiveCallbackController do
  use ExMoney.Web, :controller

  @login_logger Application.get_env(:ex_money, :login_logger_worker)

  require Logger

  alias ExMoney.{Repo, Login, Web.Plugs}

  plug Plugs.SetUser
  plug Plugs.SetLogin

  def interactive(conn, params) do
    stage = params["data"]["stage"]
    html = params["data"]["html"]
    interactive_fields_names = params["data"]["interactive_fields_names"]

    login = conn.assigns[:login]
    @login_logger.log_event("interactive", "callback_received", login.saltedge_login_id, params)

    changeset = Login.interactive_callback_changeset(login, %{
      stage: stage,
      interactive_fields_names: interactive_fields_names,
      interactive_html: html
    })

    case Repo.update(changeset) do
      {:ok, _} ->
        pid = get_channel_pid(conn.assigns[:user].id)
        store_interactive_field_names(conn.assigns[:user].id, interactive_fields_names)
        Process.send_after(pid, {:interactive_callback_received, html, interactive_fields_names}, 10)

        @login_logger.log_event("interactive", "login_updated", login.saltedge_login_id, params)

      {:error, error_changeset} ->
        @login_logger.log_event("interactive", "login_update_failed", login.saltedge_login_id, Enum.into(error_changeset.errors, %{}))
    end

    put_resp_content_type(conn, "application/json")
    |> send_resp(200, Poison.encode!(%{}))
  end

  defp get_channel_pid(user_id) do
    user_id = "user:#{user_id}"
    key = "refresh_channel_pid_#{user_id}"

    case :ets.lookup(:ex_money_cache, key) do
      [] -> nil
      [{_key, value}] -> value
    end
  end

  defp store_interactive_field_names(user_id, interactive_fields_names) do
    key = "ongoing_interactive_user:#{user_id}"

    case :ets.lookup(:ex_money_cache, key) do
      [] -> :ets.insert(:ex_money_cache, {key, interactive_fields_names})
      _ -> :ets.update_element(:ex_money_cache, key, {2, interactive_fields_names})
    end
  end
end
