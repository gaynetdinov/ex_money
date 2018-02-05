defmodule ExMoney.Web.Mobile.BudgetView do
  use ExMoney.Web, :view

  alias ExMoney.{Category, Repo}

  def draw_subcategory(%{width: "100%"}) do
    "background: darkgrey;"
  end

  def draw_subcategory(category) do
    """
    background: linear-gradient(
      to right,
      darkgrey calc(#{category[:width]}),
      darkgrey calc(#{category[:width]} - 1px),
      gainsboro calc(#{category[:width]} + 1px),
      gainsboro calc(100%)
    )
    """
  end

  def build_linear_gradient(%{width: "100%", limit: limit} = category) when not is_nil(limit) do
    """
    background: linear-gradient(
      to right,
      #{category[:css_color]} calc(#{category[:width]} - 5px),
      coral calc(#{category[:limit_percent]})
    )
    """
  end

  def build_linear_gradient(%{limit: limit, amount: amount} = category) when not is_nil(limit) and amount > limit do
    """
    background: linear-gradient(
      to right,
      #{category[:css_color]} calc(#{category[:limit_percent]}),
      #{category[:css_color]} calc(#{category[:limit_percent]} - 1px),
      coral calc(#{category[:limit_percent]} + 5px),
      #{category[:css_color]} calc(#{category[:limit_percent]} + 1px),
      #{category[:css_color]} calc(#{category[:width]}),
      whitesmoke calc(#{category[:width]} + 1px),
      whitesmoke calc(100%)
    )
    """
  end

  def build_linear_gradient(%{limit: limit} = category) when not is_nil(limit) do
    """
    background: linear-gradient(
      to right,
      #{category[:css_color]} calc(#{category[:width]}),
      whitesmoke calc(#{category[:width]} + 1px),
      whitesmoke calc(#{category[:limit_percent]} - 1px),
      coral calc(#{category[:limit_percent]} + 5px),
      whitesmoke calc(#{category[:limit_percent]}),
      whitesmoke calc(100%)
    )
    """
  end

  def build_linear_gradient(category) do
    """
    background: linear-gradient(
      to right,
      #{category[:css_color]} calc(#{category[:width]}),
      whitesmoke calc(#{category[:width]}),
      whitesmoke calc(100%)
    )
    """
  end

  def categories_chart_data([], _) do
    []
  end

  def categories_chart_data(categories, limits) do
    category_ids = Enum.map(categories, fn({category, _}) -> category.id end)
    categories = Enum.map categories, fn({category, amount}) ->
      category
      |> Map.from_struct()
      |> Map.drop([:__meta__, :parent, :transactions, :hidden, :inserted_at, :updated_at])
      |> Map.put(:amount, amount)
    end

    missing_parents =
      categories
      |> Enum.reduce([], fn(category, acc) ->
        if Enum.member?(category_ids, category.parent_id) do
          acc
        else
          [category.parent_id | acc]
        end
      end)
      |> Category.by_ids
      |> Repo.all
      |> Enum.map(fn(category) ->
        category
        |> Map.from_struct()
        |> Map.drop([:__meta__, :parent, :transactions, :hidden, :inserted_at, :updated_at])
      end)

    {parents, subcategories} =
      categories ++ missing_parents
      |> Enum.split_with(fn(category) -> is_nil(category.parent_id) end)

    categories_tree =
      Enum.reduce(parents, [], fn(parent_category, acc) ->
        children = Enum.filter(subcategories, fn(subcategory) -> subcategory.parent_id == parent_category.id end)
        children = if parent_category[:amount] do
          [parent_category | children]
        else
          children
        end

        children = Enum.map(children, fn(child) ->
          {float_amount, _} = Decimal.to_string(child[:amount], :normal)
          |> Float.parse

          positive_float = float_amount * -1
          %{child | amount: positive_float}
        end)

        children_amount =
          children
          |> Enum.map(fn(child) -> child[:amount] end)
          |> Enum.sum()

        parent_category = Map.put(parent_category, :amount, children_amount)

        [{parent_category, children} | acc]
      end)

    max_amount =
      categories_tree
      |> Enum.map(fn({parent, _}) -> parent[:amount] end)
      |> Enum.max

    categories_tree
    |> Enum.map(fn({parent, children}) ->
      parent =
        parent
        |> add_width(max_amount)
        |> add_limit(children, limits, max_amount)

      children = Enum.map(children, fn(child) ->
        child
        |> add_width(parent[:amount])
        |> add_limit(limits, parent[:amount])
      end)

      {parent, sort_subcategories(children)}
    end)
    |> sort_parent_categories()
  end

  defp add_width(category, max_amount) do
    percent = (category[:amount] * 100) / max_amount
    |> Float.round(0)
    |> :erlang.float_to_binary(decimals: 0)

    category = Map.put(category, :html_name, String.replace(category[:humanized_name], " ", "&nbsp;"))

    if percent == "0" do
      category
    else
      Map.put(category, :width, "#{percent}%")
    end
  end

  defp sort_subcategories(categories) do
    Enum.sort categories, fn(%{amount: amount_1}, %{amount: amount_2}) ->
      amount_1 > amount_2
    end
  end

  defp sort_parent_categories(categories) do
    Enum.sort categories, fn({%{amount: amount_1}, _sub_1}, {%{amount: amount_2}, _sub_2}) ->
      amount_1 > amount_2
    end
  end

  defp add_limit(category, limits, max_amount) do
    limit = limits[category[:id]]
    category = Map.put(category, :limit, limit)

    if limit do
      percent = (limit * 100) / max_amount
      |> Float.round(0)
      |> :erlang.float_to_binary(decimals: 0)
      if percent == "0" do
        category
      else
        Map.put(category, :limit_percent, "#{percent}%")
      end
    else
      category
    end
  end

  defp add_limit(category, children, limits, max_amount) do
    children_ids = Enum.map(children, fn(child) -> child[:id] end)

    limit =
      limits
      |> Enum.filter(fn({k, _v}) -> Enum.member?(children_ids, k) end)
      |> Enum.map(fn({_k, v}) -> v end)
      |> Enum.sum

    if limit == 0 do
      category
    else
      category = Map.put(category, :limit, limit)

      percent = (limit * 100) / max_amount
      |> Float.round(0)
      |> :erlang.float_to_binary(decimals: 0)
      if percent == "0" do
        category
      else
        Map.put(category, :limit_percent, "#{percent}%")
      end
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
