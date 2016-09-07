defmodule ExMoney.RuleProcessorTest do
  use ExUnit.Case

  alias ExMoney.{RuleProcessor, Repo, Transaction}

  import ExMoney.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ExMoney.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(ExMoney.Repo, {:shared, self()})

    :ok
  end

  describe "process callback" do
    setup do
      account = insert(:account)
      transaction = insert(:transaction,
        description: "bar foo baz",
        account: account,
        saltedge_account_id: account.saltedge_account_id
      )

      {:ok, transaction: transaction}
    end

    test "applies rules according to priority", %{transaction: transaction} do
      category_1 = insert(:category, name: "groceries")
      category_2 = insert(:category, name: "cafe")

      insert(:rule,
        account: transaction.account,
        type: "assign_category",
        pattern: "foo",
        priority: 1,
        target_id: category_1.id
      )

      insert(:rule,
        account: transaction.account,
        type: "assign_category",
        pattern: "foo",
        priority: 2,
        target_id: category_2.id
      )

      RuleProcessor.handle_cast({:process, transaction.id}, %{})

      updated_transaction = Repo.get(Transaction, transaction.id)

      assert updated_transaction.category_id == category_2.id
      assert updated_transaction.rule_applied
    end

    test "does not apply rule for different account", %{transaction: transaction} do
      category = insert(:category, name: "groceries")

      insert(:rule,
        type: "assign_category",
        pattern: "foo",
        priority: 1,
        target_id: category.id
      )

      RuleProcessor.handle_cast({:process, transaction.id}, %{})

      updated_transaction = Repo.get(Transaction, transaction.id)

      refute updated_transaction.category_id == category.id
      refute updated_transaction.rule_applied
    end

    test "does not apply rule when pattern does not match", %{transaction: transaction} do
      category = insert(:category, name: "groceries")

      insert(:rule,
        account: transaction.account,
        type: "assign_category",
        pattern: "something else",
        priority: 1,
        target_id: category.id
      )

      RuleProcessor.handle_cast({:process, transaction.id}, %{})

      updated_transaction = Repo.get(Transaction, transaction.id)

      refute updated_transaction.category_id == category.id
      refute updated_transaction.rule_applied
    end

    test "withdraw to cash", %{transaction: transaction} do
      cash_account = insert(:account)
      transfer_transaction = insert(:transaction,
        description: "bar foo baz",
        account: transaction.account,
        saltedge_account_id: transaction.account.saltedge_account_id,
        amount: Decimal.new(-10)
      )
      category = insert(:category, name: "withdraw")

      insert(:rule,
        account: transaction.account,
        type: "withdraw_to_cash",
        pattern: "foo",
        priority: 1,
        target_id: cash_account.id
      )

      RuleProcessor.handle_cast({:process, transfer_transaction.id}, %{})

      updated_transaction = Repo.get(Transaction, transfer_transaction.id)
      cash_transaction = Repo.get_by(Transaction, category_id: category.id)

      assert updated_transaction.rule_applied
      assert cash_transaction.account_id == cash_account.id
      assert cash_transaction.amount == Decimal.mult(updated_transaction.amount, Decimal.new(-1))
    end
  end
end
