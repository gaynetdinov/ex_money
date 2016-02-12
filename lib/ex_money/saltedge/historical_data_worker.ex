defmodule ExMoney.Saltedge.HistoricalDataWorker do
  use GenServer

  require Logger

  alias ExMoney.{Repo, Login}

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :historical_data_worker)
  end

  def handle_info({:fetch, saltedge_login_id}, state) do
    Logger.info("HistoricalDataWorker: refreshing #{saltedge_login_id} saltedge_login_id")
    login = Login.by_saltedge_login_id(saltedge_login_id) |> Repo.one

    result = send_refresh_request(saltedge_login_id)

    case result["data"]["refreshed"] do
      false ->
        Logger.info("HistoricalDataWorker: could not refresh login with fetch_all for login #{saltedge_login_id}")
      true ->
        Logger.info("HistoricalDataWorker: set SyncWorker to fetch_all transactions")
        # Tell SyncWorker to use +fetch_all+ callback when call TransactionsWorker next time.
        GenServer.cast(:sync_worker, :fetch_all)
        set_last_refreshed_at(login)
    end

    result = Supervisor.restart_child(
      ExMoney.Saltedge.FetchSupervisor,
      ExMoney.Saltedge.LoginRefreshWorker
    )
    Logger.info("HistoricalDataWorker: LoginRefreshWorker was restarted with result => #{inspect(result)}")

    {:noreply, state}
  end

  defp send_refresh_request(saltedge_login_id) do
    body = """
      { "data": { "fetch_type": "full" }}
    """

    Logger.info("HistoricalDataWorker: Refreshed login request for #{saltedge_login_id} with type 'full'.")
    result = ExMoney.Saltedge.Client.request(:put, "logins/#{saltedge_login_id}/refresh", body)

    result
  end

  defp set_last_refreshed_at(login) do
    Login.update_changeset(
      login,
      %{last_refreshed_at: :erlang.universaltime()}
    ) |> Repo.update!
  end
end
