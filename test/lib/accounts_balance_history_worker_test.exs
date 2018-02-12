defmodule ExMoney.AccountsBalanceHistoryWorkerTest do
  use ExUnit.Case

  alias ExMoney.{Accounts.BalanceHistory, Repo}

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

    h = Repo.all(BalanceHistory) |> List.first

    assert h.state == %{to_string(account_1.id) => "10", to_string(account_2.id) => "20"}
  end
end
