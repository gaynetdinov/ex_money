defmodule ExMoney.AccountsBalanceHistoryWorker do
  use GenServer

  alias ExMoney.{Repo, Account}
  alias ExMoney.Accounts.BalanceHistory

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :accounts_balance_history_worker)
  end

  def handle_call(:store_current_balance, _from, state) do
    accounts_state =
      Account
      |> Repo.all
      |> Enum.reduce(%{}, fn(account, acc) ->
        Map.put(acc, account.id, account.balance)
      end)

    %BalanceHistory{}
    |> BalanceHistory.changeset(%{state: accounts_state})
    |> Repo.insert!

    {:reply, :stored, state}
  end
end
