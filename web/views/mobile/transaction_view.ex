defmodule ExMoney.Mobile.TransactionView do
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
end
