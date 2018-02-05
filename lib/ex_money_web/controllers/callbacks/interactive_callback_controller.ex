defmodule ExMoney.Web.Callbacks.InteractiveCallbackController do
  use ExMoney.Web, :controller

  require Logger

  alias ExMoney.{Repo, Login, Web.Plugs}

  plug Plugs.SetUser
  plug Plugs.SetLogin

  def interactive(conn, params) do
    stage = params["data"]["stage"]
    html = params["data"]["html"]
    interactive_fields_names = params["data"]["interactive_fields_names"]

    login = conn.assigns[:login]

    changeset = Login.interactive_callback_changeset(login, %{
      stage: stage,
      interactive_fields_names: interactive_fields_names,
      interactive_html: html
    })

    with {:ok, _} <- Repo.update(changeset) do
      pid = get_channel_pid(conn.assigns[:user].id)
      store_interactive_field_names(conn.assigns[:user].id, interactive_fields_names)
      Process.send_after(pid, {:interactive_callback_received, html, interactive_fields_names}, 10)
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
