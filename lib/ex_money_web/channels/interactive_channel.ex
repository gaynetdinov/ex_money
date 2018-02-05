 defmodule ExMoney.InteractiveChannel do
  use Phoenix.Channel
  import Guardian.Phoenix.Socket
  require Logger

  def join("login_refresh:interactive", _message, socket) do
    user_id = socket.assigns.guardian_default_claims["aud"]
    store_pid(self(), user_id)

    Process.flag(:trap_exit, true)

    with {true, interactive_fields_names} <- ongoing_interactive?(user_id) do
      Process.send_after(self(), {:interactive_callback_received, nil, interactive_fields_names}, 10)
    end

    {:ok, socket}
  end

  def handle_info({:interactive_callback_received, _html, fields}, socket) do
    case length(fields) do
      1 ->
        push socket, "ask_otp", %{field: List.first(fields)}
      _ ->
        user = current_resource(socket)
        interactive_done(user.id)
        push socket, "not_supported_otp", %{msg: "ExMoney could not sync this account"}
    end

    {:noreply, socket}
  end

  def handle_info({:transactions_fetched, account_name, stored_transactions}, socket) do
    msg = case stored_transactions do
      0 -> "There are no new transactions"
      new -> "You've got #{new} new transaction(s)"
    end

    push socket, "transactions_fetched", %{message: msg, title: "#{account_name} account got synced"}

    {:noreply, socket}
  end

  def terminate(reason, _socket) do
    Logger.debug"> leave #{inspect reason}"

    :ok
  end

  def handle_in("send_refresh_request", %{"login_id" => saltedge_login_id}, socket) do
    body = """
      { "data": { "fetch_type": "recent" }}
    """

    result = ExMoney.Saltedge.Client.request(:put, "logins/#{saltedge_login_id}/refresh", body)
    case result do
      {:error, _reason} ->
        push socket, "refresh_request_failed", %{msg: "Could not refresh login.<br/> Try again later."}
      {:ok, _response} ->
        user = current_resource(socket)
        user_id = "user:#{user.id}"
        cache_ongoing_interactive(user_id)

        push socket, "refresh_request_ok", %{msg: "Request has been sent.<br/> Waiting for a response..."}
    end

    {:reply, :ok, socket}
  end

  def handle_in("send_otp", %{"otp" => otp, "login_id" => saltedge_login_id, "field" => field}, socket) do
    body = """
      { "data": { "fetch_type": "recent", "credentials": { "#{field}": "#{otp}" }}}
    """

    {:ok, response} = ExMoney.Saltedge.Client.request(:put, "logins/#{saltedge_login_id}/interactive", body)
    Logger.info("OTP has been send with the following result => #{inspect(response)}")

    push socket, "otp_sent", %{title: "Transactions will by synced shortly", msg: "OTP has been sent"}

    user = current_resource(socket)
    interactive_done(user.id)

    {:reply, :ok, socket}
  end

  def handle_in("cancel_otp", _, socket) do
    user = current_resource(socket)
    interactive_done(user.id)

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

  defp cache_ongoing_interactive(user_id) do
    user_id = String.downcase(user_id)

    key = "ongoing_interactive_#{user_id}"

    case :ets.lookup(:ex_money_cache, key) do
      [] -> :ets.insert(:ex_money_cache, {key, true})
      _ -> :ets.update_element(:ex_money_cache, key, {2, true})
    end
  end

  defp ongoing_interactive?(user_id) do
    user_id = String.downcase(user_id)

    key = "ongoing_interactive_#{user_id}"

    case :ets.lookup(:ex_money_cache, key) do
      [] -> false
      [{_key, false}] -> false
      [{_key, true}] -> true
      [{_key, interacitve_field_names}] -> {true, interacitve_field_names}
    end
  end

  defp interactive_done(user_id) do
    user_id = "user:#{user_id}"
    key = "ongoing_interactive_#{user_id}"
    :ets.update_element(:ex_money_cache, key, {2, false})
  end
end
