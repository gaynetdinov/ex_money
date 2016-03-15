 defmodule ExMoney.InteractiveChannel do
  use Phoenix.Channel
  import Guardian.Phoenix.Socket
  require Logger

  def join("login_refresh:interactive", _message, socket) do
    user_id = socket.assigns.guardian_default_claims["aud"]
    store_pid(self, user_id)

    Process.flag(:trap_exit, true)

    if ongoing_otp?(user_id) do
      Process.send_after(self, {:interactive, "", ""}, 10)
    end

    {:ok, socket}
  end

  def handle_info({:interactive, _html, fields}, socket) do
    push socket, "otp", %{field: List.first(fields)}

    {:noreply, socket}
  end

  def terminate(reason, _socket) do
    Logger.debug"> leave #{inspect reason}"
    :ok
  end

  def handle_in("refresh", %{"login_id" => login_id}, socket) do
    body = """
      { "data": { "fetch_type": "recent" }}
    """

    result = ExMoney.Saltedge.Client.request(:put, "logins/#{login_id}/refresh", body)
    case result["data"]["refreshed"] do
      false ->
        push socket, "refresh_failed", %{msg: "Could not refresh login. Try again later."}
      true ->
        user = current_resource(socket)
        user_id = "user:#{user.id}"
        cache_ongoing_otp(user_id)
        push socket, "refresh_ok", %{msg: "Refresh request has been successfully sent"}
    end

    {:reply, :ok, socket}
  end

  def handle_in("otp", %{"otp" => otp, "login_id" => login_id, "field" => field}, socket) do
    body = """
      { "data": { "fetch_type": "recent", "credentials": { "#{field}": "#{otp}" }}}
    """

    ExMoney.Saltedge.Client.request(:put, "logins/#{login_id}/interactive", body)

    push socket, "otp_ok", %{msg: "OTP has been successfully sent"}

    user = current_resource(socket)
    otp_done(user.id)

    {:reply, :ok, socket}
  end

  def handle_in("otp_cancel", _, socket) do
    user = current_resource(socket)
    otp_done(user.id)

    {:reply, :ok, socket}
  end

  defp store_pid(pid, user_id) do
    user_id = String.downcase(user_id)

    key = "refresh_channel_pid_#{user_id}"
    case :ets.lookup(:ex_money_cache, key) do
      [] -> :ets.insert(:ex_money_cache, {key, pid})
      _ -> :ets.update_element(:ex_money_cache, key, {2, pid})
    end
  end

  defp cache_ongoing_otp(user_id) do
    user_id = String.downcase(user_id)

    key = "ongoing_interactive_#{user_id}"

    case :ets.lookup(:ex_money_cache, key) do
      [] -> :ets.insert(:ex_money_cache, {key, true})
      _ -> :ets.update_element(:ex_money_cache, key, {2, true})
    end
  end

  defp ongoing_otp?(user_id) do
    user_id = String.downcase(user_id)

    key = "ongoing_interactive_#{user_id}"

    case :ets.lookup(:ex_money_cache, key) do
      [] -> false
      [{_key, false}] -> false
      _ -> true
    end
  end

  defp otp_done(user_id) do
    user_id = "user:#{user_id}"
    key = "ongoing_interactive_#{user_id}"
    :ets.update_element(:ex_money_cache, key, {2, false})
  end
end
