defmodule ExMoney.Web.Mobile.AccountView do
  use ExMoney.Web, :view

  alias ExMoney.{Category, Repo}

  def categories_chart_data(categories) when map_size(categories) == 0 do
    []
  end

  # FIXME Oh my, that's got complicated.
  # I hope there is a better way to generate data for the chart.
  def categories_chart_data(categories) do
    parent_categories = Enum.map(categories, fn({_id, category}) -> category.parent_id end)
    |> Enum.reject(&(is_nil(&1)))
    |> Category.by_ids
    |> Repo.all
    |> Enum.reduce(%{}, fn(category, acc) ->
      case Map.has_key?(acc, category.id) do
        true -> acc
        false -> Map.put(acc, category.id, category)
      end
    end)

    categories_tree = Enum.reduce(categories, %{}, fn({id, category}, acc) ->
      if is_nil(category.parent_id) do
        case Map.has_key?(acc, id) do
          false -> Map.put(acc, id, [])
          true -> acc
        end
      else
        case Map.has_key?(acc, category.parent_id) do
          false -> Map.put(acc, category.parent_id, [id])
          true ->
            sub_categories = Map.get(acc, category.parent_id, [])
            Map.put(acc, category.parent_id, [id | sub_categories])
        end
      end
    end)

    max_amount = Enum.reduce(categories_tree, [], fn({id, sub_category_ids}, acc) ->
      category = parent_categories[id] || categories[id]

      case sub_category_ids do
        [] ->
          [category.amount | acc]
        _ ->
          sub_amount = Enum.reduce(sub_category_ids, 0, fn(sub_category_id, acc) ->
            acc + categories[sub_category_id].amount
          end)

          total_amount = if categories[category.id] do
            sub_amount + categories[category.id].amount
          else
            sub_amount
          end

          [total_amount | acc]
      end
    end) |> Enum.max

    Enum.reduce(categories_tree, [], fn({id, sub_category_ids}, acc) ->
      category = parent_categories[id] || categories[id]
      amount = case sub_category_ids do
        [] -> category.amount
        _ ->
          sub_categories_sum = Enum.reduce(sub_category_ids, 0, fn(sub_category_id, acc) ->
            acc + categories[sub_category_id].amount
          end)

          if categories[category.id] do
            sub_categories_sum + categories[category.id].amount
          else
            sub_categories_sum
          end
      end

      sub_categories = Enum.reduce(sub_category_ids, [], fn(sub_category_id, acc) ->
        sub_category = categories[sub_category_id]
        sub_category = add_width(sub_category, sub_category.amount, amount)

        if sub_category do
          [sub_category | acc]
        else
          acc
        end
      end)
      |> Enum.sort(fn(
        {_id_1, _cat_1, _color_1, _width_1, amount_1},
        {_id_2, _cat_2, _color_2, _width_2, amount_2}) ->
          amount_1 > amount_2
      end)

      category = add_width(category, amount, max_amount)

      if category do
        [{category, sub_categories} | acc]
      else
        acc
      end
    end)
    |> Enum.sort(fn(
      {{_id_1, _cat_1, _color_1, _width_1, amount_1}, _sub_categories_1},
      {{_id_2, _cat_2, _color_2, _width_2, amount_2}, _sub_categories_2}) ->
        amount_1 > amount_2
    end)
  end

  defp add_width(category, amount, max_amount) do
    percent = (amount * 100) / max_amount
    |> Float.round(0)
    |> :erlang.float_to_binary(decimals: 0)

    if percent == "0" do
      nil
    else
      html_name = String.replace(category.humanized_name, " ", "&nbsp;")
      {category.id, html_name, category.css_color, "#{percent}%", amount}
    end
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
