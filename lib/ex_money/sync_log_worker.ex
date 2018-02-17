defmodule ExMoney.SyncLogWorker do
  use GenServer
  require Logger

  alias ExMoney.{SyncLogApi, Transactions}

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :sync_log_worker)
  end

  def handle_cast({:store_transaction, transaction_id}, state) do
    payload =
      Transactions.get_transaction(transaction_id)
      |> Map.from_struct()
      |> Map.drop([:__meta__, :user_id, :account, :category, :saltedge_account, :user])

    SyncLogApi.store("Transaction", "create", payload)

    {:noreply, state}
  end
end
