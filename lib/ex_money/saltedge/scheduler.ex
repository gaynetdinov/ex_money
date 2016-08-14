defmodule ExMoney.Saltedge.Scheduler do
  use GenServer
  require Logger

  @interval 60 * 1000

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :scheduler)
  end

  def init(:ok) do
    Process.send_after(self, :schedule, 100)

    {:ok, %{}}
  end

  def handle_info(:schedule, state) do
    case current_hour do
      hour when hour >= 0 and hour < 7 ->
        stop_worker(:login_refresh_worker)
        stop_worker(:idle_worker)

        Process.send_after(self, :start_worker, 7 * 60 * 60 * 1000)
        Logger.info("Workers have been scheduled to start in 7 hours")
      _ ->
        Process.send_after(self, :schedule, @interval)
    end

    {:noreply, state}
  end

  def handle_info(:start_worker, state) do
    start_worker(:login_refresh_worker, ExMoney.Saltedge.LoginRefreshWorker)
    start_worker(:idle_worker, ExMoney.IdleWorker)

    Process.send_after(self, :schedule, @interval)

    {:noreply, state}
  end

  defp start_worker(name, ref) do
    Logger.info("Starting worker #{name}...")
    pid = Process.whereis(name)

    if !pid do
      result = Supervisor.restart_child(ExMoney.Supervisor, ref)

      Logger.info("Time to wake up, #{ref} has been started with result => #{inspect(result)}")
    end
  end

  defp stop_worker(name) do
    Logger.info("Stopping worker #{name}...")
    pid = Process.whereis(name)

    if pid && Process.alive?(pid) do
      result = GenServer.call(name, :stop)
      Logger.info("Time to sleep, #{name} has been stopped with result => #{inspect(result)}")
    end
  end

  defp current_hour do
    {_date, {hour, _min, _sec}} = :calendar.local_time()

    hour
  end
end
