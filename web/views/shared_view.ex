defmodule ExMoney.SharedView do
  use ExMoney.Web, :view

  def sort_by_inserted_at(transactions) do
    Enum.sort(transactions, fn(tr_1, tr_2) ->
      Ecto.Date.compare(tr_1.inserted_at, tr_2.inserted_at) != :lt
    end)
  end

  def description(transaction) do
    case transaction.transaction_info do
      nil -> transaction.description
      ti -> ti.payee
    end
  end

  def category_name(nil), do: ""

  def category_name(category) do
    category.humanized_name
  end
end
