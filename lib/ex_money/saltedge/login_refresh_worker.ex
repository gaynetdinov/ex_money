defmodule ExMoney.Saltedge.LoginRefreshWorker do
  use GenServer

  require Logger

  alias ExMoney.Repo
  alias ExMoney.Login

  @interval 3_600_000

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :login_refresh_worker)
  end

  def init(:ok) do
    logins = Repo.all(Login)

    case logins do
      [] -> :ignore
      logins ->
        Enum.each(logins, fn(login) ->
          Process.send_after(self(), {:refresh, login}, 100)
        end)

        {:ok, {}}
    end
  end

  def handle_info({:refresh, login}, state) do
    last_refreshed_at = last_refreshed_at(login.last_refreshed_at)

    case Timex.Date.diff(last_refreshed_at, Timex.Date.now, :secs) do
      secs when secs >= 3600 ->
        refresh_login(login, 5)

        Process.send_after(self(), {:refresh, login}, @interval)
      secs when secs < 3600 ->
        next_run = 3600 - secs

        Process.send_after(self(), {:refresh, login}, next_run * 1000)
    end

    {:noreply, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  defp refresh_login(login, attempts) do
    body = """
      { "data": { "fetch_type": "recent" }}
    """

    result = ExMoney.Saltedge.Client.request(:put, "logins/#{login.saltedge_login_id}/refresh", body)
    Logger.info("Refreshed login #{login.saltedge_login_id} with result => #{inspect(result)}")

    case result["data"]["refreshed"] do
      false when attempts > 0 ->
        :timer.sleep(5000)
        refresh_login(login, attempts - 1)
      false ->
        Logger.error("After 5 attempts login was not refreshed")
      true ->
        Logger.info("Login was successfully refreshed!")
    end
  end

  # Use now - 61 minutes to trigger syncing when last_refreshed_at is nil
  defp last_refreshed_at(nil) do
    Timex.Date.subtract(Timex.Date.now, Timex.Time.to_timestamp(61, :mins))
  end

  defp last_refreshed_at(last_refreshed_at) do
    Ecto.DateTime.to_erl(last_refreshed_at) |> Timex.Date.from
  end
end
