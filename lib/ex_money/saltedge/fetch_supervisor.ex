defmodule ExMoney.Saltedge.FetchSupervisor do
  use Supervisor

  def start_link(_opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: ExMoney.Saltedge.FetchSupervisor)
  end

  def init(:ok) do
    children = [
      worker(ExMoney.Saltedge.LoginRefreshWorker, [], restart: :transient),
      worker(ExMoney.Saltedge.HistoricalDataWorker, []),
    ]

    supervise(children, strategy: :one_for_all)
  end
end
