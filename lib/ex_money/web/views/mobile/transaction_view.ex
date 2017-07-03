defmodule ExMoney.Web.Mobile.TransactionView do
  use ExMoney.Web, :view

  def balance(transactions) do
    Enum.reduce(transactions, Decimal.new(0), fn(transaction, acc) ->
      Decimal.add(acc, transaction.amount)
    end)
  end

  def description(transaction) do
    case transaction.transaction_info do
      nil -> transaction.description
      ti -> ti.payee
    end
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
