defmodule ExMoney.Web.DashboardView do
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
end
