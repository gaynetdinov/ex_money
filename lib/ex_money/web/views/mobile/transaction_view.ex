defmodule ExMoney.Web.Mobile.TransactionView do
  use ExMoney.Web, :view
  alias ExMoney.Transaction

  def balance(transactions) do
    Enum.reduce(transactions, Decimal.new(0), fn(transaction, acc) ->
      Decimal.add(acc, transaction.amount)
    end)
  end

  def description(%Transaction{extra: nil} = transaction) do
    transaction.description
  end

  def description(transaction) do
    transaction.extra["payee"]
  end

  def render("delete.json", %{account_id: account_id, new_balance: new_balance}) do
    %{
      account_id: account_id,
      new_balance: new_balance,
    }
  end

  def render("delete.json", %{new_balance: new_balance}) do
    %{new_balance: new_balance}
  end
end
