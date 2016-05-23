defmodule ExMoney do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ets.new(:ex_money_cache, [:set, :public, :named_table])

    children = [
      supervisor(ExMoney.Endpoint, []),
      worker(ExMoney.Repo, []),
      worker(ExMoney.Saltedge.TransactionsWorker, []),
      worker(ExMoney.IdleWorker, [], restart: :transient),
      worker(ExMoney.Saltedge.Scheduler, []),
      worker(ExMoney.Saltedge.SyncWorker, []),
      worker(ExMoney.RuleProcessor, []),
      worker(ExMoney.Saltedge.LoginLogger, []),
      worker(ExMoney.Saltedge.LoginRefreshWorker, [], restart: :transient),
      worker(ExMoney.Saltedge.SyncBuffer, [])
    ]

    opts = [strategy: :one_for_one, name: ExMoney.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    ExMoney.Endpoint.config_change(changed, removed)
    :ok
  end
end
