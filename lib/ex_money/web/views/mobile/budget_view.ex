defmodule ExMoney.Web.Mobile.BudgetView do
  use ExMoney.Web, :view

  alias ExMoney.{Category, Repo}

  def categories_chart_data(categories, _) when map_size(categories) == 0 do
    []
  end

  # FIXME Oh my, that's got complicated.
  # I hope there is a better way to generate data for the chart.
  def categories_chart_data(categories, limits) do
    parents_with_children = Category.parents_with_children() |> Repo.all |> Enum.into(%{})
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
          false ->
            Map.put(acc, category.parent_id, [id])
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
        sub_category = add_limit(sub_category, limits)

        if sub_category do
          [sub_category | acc]
        else
          acc
        end
      end)
      |> Enum.sort(fn(
        {_id_1, _cat_1, _color_1, _width_1, amount_1, _limit_1},
        {_id_2, _cat_2, _color_2, _width_2, amount_2, _limit_2}) ->
          amount_1 > amount_2
      end)

      category = add_width(category, amount, max_amount)
      category = add_limit_to_top_category(category, limits, parents_with_children)

      if category do
        [{category, sub_categories} | acc]
      else
        acc
      end
    end)
    |> Enum.sort(fn(
      {{_id_1, _cat_1, _color_1, _width_1, amount_1, _limit_1}, _sub_categories_1},
      {{_id_2, _cat_2, _color_2, _width_2, amount_2, _limit_2}, _sub_categories_2}) ->
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

  defp add_limit(nil, _), do: nil
  defp add_limit(category, limits) do
    Tuple.append(category, limits[elem(category, 0)])
  end

  defp add_limit_to_top_category(nil, _, _), do: nil
  defp add_limit_to_top_category({id, _, _, _, _} = category, limits, parents_with_children) do
    children_categories = parents_with_children[id] || []
    limit =
      limits
      |> Enum.filter(fn({k, v}) -> Enum.member?(children_categories, k) end)
      |> Enum.map(fn({_k, v}) -> v end)
      |> Enum.sum

    if limit == 0 do
      Tuple.append(category, nil)
    else
      Tuple.append(category, limit)
    end
  end

  def balance(transactions) do
    Enum.reduce transactions, Decimal.new(0), fn(tr, acc) ->
      Decimal.add(acc, tr.amount)
    end
  end

  def expenses(transactions) do
    transactions
    |> Enum.reject(fn(tr) ->
      Decimal.compare(tr.amount, Decimal.new(0)) != Decimal.new(-1) or tr.category.name == "withdraw"
    end)
    |> Enum.reduce(Decimal.new(0), fn(transaction, acc) ->
      Decimal.add(acc, transaction.amount)
    end)
  end

  def income(transactions) do
    transactions
    |> Enum.reject(fn(tr) ->
      Decimal.compare(tr.amount, Decimal.new(0)) == Decimal.new(-1) or tr.category.name == "withdraw"
    end)
    |> Enum.reduce(Decimal.new(0), fn(transaction, acc) ->
      Decimal.add(acc, transaction.amount)
    end)
  end
end
