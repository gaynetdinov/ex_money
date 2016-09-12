defmodule ExMoney.AccountsBalanceHistoryWorker do
  use GenServer

  alias ExMoney.{Account, Repo, AccountsBalanceHistory}

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :accounts_balance_history_worker)
  end

  def handle_call(:store_current_balance, _from, state) do
    Account
    |> Repo.all
    |> Enum.each(fn(account) ->
      %AccountsBalanceHistory{}
      |> AccountsBalanceHistory.changeset(%{account_id: account.id, balance: account.balance})
      |> Repo.insert!
    end)

    {:reply, :stored, state}
  end
end
