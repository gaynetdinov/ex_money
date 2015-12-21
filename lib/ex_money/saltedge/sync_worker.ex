defmodule ExMoney.Saltedge.SyncWorker do
  use GenServer
  require Logger

  alias ExMoney.Account
  alias ExMoney.Repo

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :sync_worker)
  end

  def handle_cast(:sync, user_id, saltedge_login_id, state) do
    ExMoney.Saltedge.Login.sync(user_id, saltedge_login_id)

    ExMoney.Saltedge.Account.sync([saltedge_login_id])

    accounts = Account.by_saltedge_login_id([saltedge_login_id])
    |> Repo.all
    |> Enum.map(fn(account) ->
      {:ok, transactions_fetched} = GenServer.call(:transactions_worker, {:fetch_recent, account.saltedge_account_id})
      Logger.info("#{transactions_fetched} transactions were fetch for #{account.name} account")
    end)
  end
end
