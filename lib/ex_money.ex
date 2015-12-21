defmodule ExMoney do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(ExMoney.Endpoint, []),
      worker(ExMoney.Repo, []),
      worker(ExMoney.Saltedge.LoginRefreshWorker, [], restart: :transient),
      worker(ExMoney.Saltedge.TransactionsWorker, []),
      worker(ExMoney.Saltedge.Scheduler, [])
    ]

    opts = [strategy: :one_for_one, name: ExMoney.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    ExMoney.Endpoint.config_change(changed, removed)
    :ok
  end
end
