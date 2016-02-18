defmodule ExMoney.Saltedge.SyncBuffer do
  use GenServer
  require Logger

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :sync_buffer)
  end

  def handle_cast({:schedule, :sync, target}, state) do
    schedule_sync_worker(target)

    {:noreply, state}
  end

  def handle_cast({:schedule, :refresh, target}, state) do
    schedule_login_refresh_worker(target)

    {:noreply, state}
  end

  def handle_info({:schedule_sync_worker, login}, state) do
    GenServer.cast(:sync_worker, {:sync, login.user_id, login.saltedge_login_id})

    {:noreply, state}
  end

  def handle_info({:schedule_login_refresh_worker, login_id}, state) do
    worker_pid = Process.whereis(:login_refresh_worker)
    case Process.alive?(worker_pid) do
      true ->
        Process.send_after(:login_refesh_worker, {:fetch, login_id}, 10)
        Logger.info("Login #{login_id} has been scheduled by LoginRefreshWorker")
      false ->
        result = Supervisor.restart_child(
          ExMoney.Supervisor,
          ExMoney.Saltedge.LoginRefreshWorker
        )
        Logger.info("LoginRefreshWorker has been started with result => #{inspect(result)}")
    end

    {:noreply, state}
  end

  # Buffer for LoginRefreshWorker.
  defp schedule_login_refresh_worker(target) do
    key = "login_refesh_worker_reference_#{target}"
    case :ets.lookup(:ex_money_cache, key) do
      [] ->
        ref = Process.send_after(self(), {:schedule_login_refresh_worker, target}, 300 * 1000)
        Logger.info("Login id #{target} has been scheduled to be refreshed in 5 mins")
        :ets.insert(:ex_money_cache, {key, ref})
      [{_, ref}] ->
        Process.cancel_timer(ref)
        new_ref = Process.send_after(self(), {:schedule_login_refresh_worker, target}, 300 * 1000)
        Logger.info("Login id #{target} has been rescheduled to be refreshed in 5 mins")
        :ets.update_element(:ex_money_cache, key, {2, new_ref})
    end
  end

  # Buffer for SyncWorker.
  defp schedule_sync_worker(target) do
    key = "sync_worker_reference_#{target.saltedge_login_id}"
    case :ets.lookup(:ex_money_cache, key) do
      [] ->
        ref = Process.send_after(self(), {:schedule_sync_worker, target}, 60 * 1000)
        Logger.info("Login #{target.saltedge_login_id} has been scheduled to be synced in 1 min")
        :ets.insert(:ex_money_cache, {key, ref})
      [{_, ref}] ->
        Process.cancel_timer(ref)
        new_ref = Process.send_after(self(), {:schedule_sync_worker, target}, 60 * 1000)
        Logger.info("Login #{target.saltedge_login_id} has been rescheduled to be synced in 1 min")
        :ets.update_element(:ex_money_cache, key, {2, new_ref})
    end
  end
end
