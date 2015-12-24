defmodule ExMoney.DashboardView do
  use ExMoney.Web, :view

  def day_total(transactions) do
    Enum.reduce(transactions, Decimal.new(0), fn(transaction, acc) ->
      Decimal.add(acc, transaction.amount)
    end)
  end
end
