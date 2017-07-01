defmodule ExMoney.Scheduler do
  use GenServer
  require Logger

  @interval 60 * 1000

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :scheduler)
  end

  def init(:ok) do
    Process.send_after(self(), :schedule, 100)

    {:ok, %{}}
  end

  def handle_info(:schedule, state) do
    case current_hour() >= hour_to_sleep() do
      true ->
        store_accounts_balance()
        stop_worker(:login_refresh_worker)
        stop_worker(:idle_worker)
      false ->
        Process.send_after(self(), :schedule, @interval)
    end

    {:noreply, state}
  end

  defp store_accounts_balance() do
    :stored = GenServer.call(:accounts_balance_history_worker, :store_current_balance)
  end

  defp stop_worker(name) do
    Logger.info("Stopping worker #{name}...")
    pid = Process.whereis(name)

    if pid && Process.alive?(pid) do
      result = GenServer.call(name, :stop)
      Logger.info("Time to sleep, #{name} has been stopped with result => #{inspect(result)}")
    end
  end

  defp current_hour() do
    {_date, {hour, _min, _sec}} = :calendar.local_time()

    hour
  end

  defp hour_to_sleep() do
    Application.get_env(:ex_money, :hour_to_sleep)
  end
end
