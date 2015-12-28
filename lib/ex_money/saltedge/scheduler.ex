defmodule ExMoney.Saltedge.Scheduler do
  use GenServer
  require Logger

  @interval 60 * 1000

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :scheduler)
  end

  def init(:ok) do
    Process.send_after(self(), :schedule, 100)

    {:ok, {}}
  end

  def handle_info(:schedule, state) do
    case current_hour() do
      hour when hour >= 0 and hour < 7 ->
        # FIXME: handle genserver answer
        result = GenServer.call(:login_refresh_worker, :stop)
        Logger.info("Time to sleep, LoginRefreshWorker has been stopped with result => #{inspect(result)}")
        # Start transactions worker in 7 hours
        Process.send_after(self(), :start_worker, 7 * 60 * 60 * 1000)

      _ -> Process.send_after(self(), :schedule, @interval)
    end

    {:noreply, state}
  end

  def handle_info(:start_worker, state) do
    result = Supervisor.restart_child(
      ExMoney.FetchSupervisor,
      ExMoney.Saltedge.LoginRefreshWorker
    )
    Logger.info("Time to wake up, LoginRefreshWorker has been started with result => #{inspect(result)}")

    Process.send_after(self(), :schedule, @interval)

    {:noreply, state}
  end

  defp current_hour do
    {_date, {hour, _min, _sec}} = :calendar.local_time()

    hour
  end
end
