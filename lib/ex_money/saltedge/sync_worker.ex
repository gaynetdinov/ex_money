defmodule ExMoney.Saltedge.SyncWorker do
  use GenServer
  require Logger

  alias ExMoney.{Account, Repo}

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :sync_worker)
  end

  def init(:ok), do: {:ok, %{}}

  def handle_cast({:sync, user_id, saltedge_login_id}, state) do
    ExMoney.Saltedge.Login.sync(user_id, saltedge_login_id)

    ExMoney.Saltedge.Account.sync(user_id, saltedge_login_id)

    fetch_type = fetch_type(state)
    Account.by_saltedge_login_id([saltedge_login_id])
    |> Repo.all
    |> Enum.map(fn(account) ->
      {:ok, stored_transactions, fetched_transactions} = GenServer.call(
        :transactions_worker,
        {fetch_type, account.saltedge_account_id, user_id}
      )
      Logger.info("Fetched #{fetched_transactions}, stored #{stored_transactions}, fetched with type #{fetch_type} for #{account.name} account")
    end)

    {:noreply, %{}}
  end

  def handle_cast(:fetch_all, _state) do
    {:noreply, %{fetch_all: true}}
  end

  defp fetch_type(%{fetch_all: true}), do: :fetch_all
  defp fetch_type(_), do: :fetch_recent
end
