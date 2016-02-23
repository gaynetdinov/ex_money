defmodule ExMoney.Mobile.DashboardView do
  use ExMoney.Web, :view

   def categories_chart_data([]), do: []

   def categories_chart_data(categories) do
     {_category, _color, max} = Enum.max_by(categories, fn({_category, _color, amount}) -> amount end)

     Enum.reduce(categories, [], fn({category, color, amount}, acc) ->
       percent = (amount * 100) / max
       |> Float.round(0)
       |> Float.to_string(compact: true, decimals: 0)

       if percent == "0" do
         acc
       else
         [{category, color, "#{percent}%", amount} | acc]
       end

     end)
     |> Enum.sort(fn(
       {_cat_1, _color_1, _width_1, amount_1},
       {_cat_2, _color_2, _width_2, amount_2}) ->
       amount_1 > amount_2
     end)
   end

  def expenses(transactions) do
    Enum.reject(transactions, fn(transaction) ->
      Decimal.compare(transaction.amount, Decimal.new(0)) != Decimal.new(-1)
    end) |>
    Enum.reduce(Decimal.new(0), fn(transaction, acc) ->
      Decimal.add(acc, transaction.amount)
    end)
  end

  def income(transactions) do
    Enum.reject(transactions, fn(transaction) ->
      Decimal.compare(transaction.amount, Decimal.new(0)) == Decimal.new(-1)
    end) |>
    Enum.reduce(Decimal.new(0), fn(transaction, acc) ->
      Decimal.add(acc, transaction.amount)
    end)
  end

  def description(transaction) do
    case transaction.transaction_info do
      nil -> transaction.description
      ti -> ti.payee
    end
  end

  def recent_diff(recent_diff, currency_label) do
    recent_diff_compare = Decimal.compare(recent_diff, Decimal.new(0))
    recent_diff_str = Decimal.to_string(recent_diff)

    cond do
      recent_diff_compare == Decimal.new(1) ->
        "<span style='color:green'>" <> recent_diff_str <> currency_label <> "&#x25B2; &nbsp;</span>"
      recent_diff_compare == Decimal.new(0) -> ""
      recent_diff_compare == Decimal.new(-1) ->
        "<span style='color:red'>" <> recent_diff_str <> currency_label <> "&#x25BC; &nbsp;</span>"
    end
  end

  def sort_by_inserted_at(transactions) do
    Enum.sort(transactions, fn(tr_1, tr_2) ->
      Ecto.Date.compare(tr_1.inserted_at, tr_2.inserted_at) != :lt
    end)
  end
end
