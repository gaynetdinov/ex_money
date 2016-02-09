defmodule ExMoney.Mobile.AccountView do
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
        html_category = String.replace(category, " ", "&nbsp;")
        [{html_category, color, "#{percent}%", amount} | acc]
      end

    end)
    |> Enum.sort(fn(
      {_cat_1, _color_1, _width_1, amount_1},
      {_cat_2, _color_2, _width_2, amount_2}) ->
        amount_1 > amount_2
    end)
  end

  def balance(transactions) do
    Enum.reduce(transactions, Decimal.new(0), fn(transaction, acc) ->
      Decimal.add(acc, transaction.amount)
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
end
