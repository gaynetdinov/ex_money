defmodule ExMoney.Saltedge.TransactionsScheduler do
  use GenServer
  require Logger

  alias ExMoney.Account
  alias ExMoney.Repo

  @interval 60 * 1000

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :transactions_scheduler)
  end

  def init(:ok) do
    Process.send_after(self(), :schedule, @interval)

    {:ok, {}}
  end

  def handle_info(:schedule, state) do
    case current_hour() do
      hour when hour >= 0 and hour < 7 ->
        # FIXME: handle genserver answer
        GenServer.call(:transactions_worker, :stop)
        # Start transactions worker in 7 hours
        Process.send_after(self(), :start_worker, 7 * 60 * 60 * 1000)

      _ -> Process.send_after(self(), :schedule, @interval)
    end

    {:noreply, state}
  end

  def handle_info(:start_worker, state) do
    Supervisor.restart_child(
      ExMoney.Supervisor,
      ExMoney.Saltedge.TransactionsWorker
    )

    Process.send_after(self(), :schedule, @interval)

    {:noreply, state}
  end

  defp current_hour do
    {_date, {hour, _min, _sec}} = :calendar.local_time()

    hour
  end
end
