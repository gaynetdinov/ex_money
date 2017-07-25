defmodule ExMoney.RuleProcessor do
  use GenServer

  alias ExMoney.{Repo, Rule, Transaction, Category, Account}

  import Ecto.Query

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :rule_processor)
  end

  def handle_cast({:process, transaction_id}, _state) do
    transaction = Transaction
    |> where([tr], tr.id == ^transaction_id)
    |> Repo.one

    Rule
    |> where([r], r.account_id == ^transaction.account_id)
    |> order_by(asc: :priority)
    |> Repo.all
    |> Enum.each(fn(rule) ->
      case rule.type do
        "assign_category" -> assign_category(rule, transaction)
        "withdraw_to_cash" -> withdraw_to_cash(rule, transaction)
      end
    end)

    {:noreply, %{}}
  end

  def handle_cast({:process_all, rule_id}, _state) do
    rule = Repo.get(Rule, rule_id)

    transactions = Repo.all(from tr in Transaction,
      where: tr.account_id == ^rule.account_id,
      where: tr.rule_applied == false,
      where: fragment("description ~* ?", ^rule.pattern) or fragment("extra->>'payee' ~* ?", ^rule.pattern))

    Enum.each(transactions, fn(tr) ->
      GenServer.cast(:rule_processor, {:process, tr.id})
    end)

    {:noreply, %{}}
  end

  defp assign_category(rule, transaction) do
    {:ok, re} = Regex.compile(rule.pattern, "i")

    if Regex.match?(re, transaction_description(transaction, transaction.extra)) do
      Transaction.update_changeset(transaction, %{category_id: rule.target_id, rule_applied: true})
      |> Repo.update!
    end
  end

  defp withdraw_to_cash(rule, transaction) do
    {:ok, re} = Regex.compile(rule.pattern, "i")
    withdraw_category = Category.by_name_with_hidden("withdraw") |> Repo.one

    account = Repo.get(Account, rule.target_id)

    if Regex.match?(re, transaction_description(transaction, transaction.extra)) &&
      Decimal.compare(transaction.amount, Decimal.new(0)) == Decimal.new(-1) do

      Repo.transaction(fn ->
        Transaction.changeset_custom(%Transaction{},
          %{
            "amount" => transaction.amount,
            "category_id" => withdraw_category.id,
            "account_id" => account.id,
            "made_on" => transaction.made_on,
            "user_id" => transaction.user_id,
            "type" => "expense"
          }
        )
        |> Repo.insert!

        Transaction.update_changeset(transaction, %{rule_applied: true, category_id: withdraw_category.id})
        |> Repo.update!

        # transaction.amount is negative, sub with something negative -> add
        new_balance = Decimal.sub(account.balance, transaction.amount)
        Account.update_custom_changeset(account, %{balance: new_balance})
        |> Repo.update!
      end)
    end
  end

  defp transaction_description(transaction, extra) when extra == %{} or is_nil(extra), do: transaction.description
  defp transaction_description(transaction, extra) do
    transaction.description <> " " <> to_string(extra["payee"])
  end
end
