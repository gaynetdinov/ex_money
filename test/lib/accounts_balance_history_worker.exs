defmodule ExMoney.AccountsBalanceHistoryWorkerTest do
  use ExUnit.Case

  alias ExMoney.{AccountsBalanceHistory, Repo}

  import ExMoney.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ExMoney.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(ExMoney.Repo, {:shared, self()})

    account_1 = insert(:account, balance: Decimal.new(10))
    account_2 = insert(:account, balance: Decimal.new(20))

    {:ok, account_1: account_1, account_2: account_2}
  end

  test "store current balance", %{account_1: account_1, account_2: account_2} do
    assert :stored == GenServer.call(:accounts_balance_history_worker, :store_current_balance)

    history_1 = Repo.get_by(AccountsBalanceHistory, account_id: account_1.id)
    history_2 = Repo.get_by(AccountsBalanceHistory, account_id: account_2.id)

    assert Decimal.new(10) == history_1.balance
    assert Decimal.new(20) == history_2.balance
  end
end
