defmodule ExMoney.Web.Mobile.Setting.BudgetController do
  use ExMoney.Web, :controller

  alias ExMoney.{Account, Repo, Category, BudgetTemplate, BudgetItem, DateHelper, Budget}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def show(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    budget_template = BudgetTemplate.by_user_id(user.id) |> Repo.one

    if budget_template do
      accounts =
        budget_template.accounts
        |> Enum.map(fn(account_id) -> Repo.get(Account, account_id).name end)
        |> Enum.join(",")

      current_budget = Budget.current_by_user_id(user.id) |> Repo.one
      items = Enum.sort budget_template.items, fn(item_1, item_2) ->
        Decimal.compare(item_1.amount, item_2.amount) == Decimal.new(1)
      end

      budget_expenses = items_sum(budget_template.items)

      expectation =
        budget_template.income
        |> Decimal.sub(budget_template.goal)
        |> Decimal.sub(budget_expenses)

      render conn, :show,
        expectation: expectation,
        budget_expenses: budget_expenses,
        items: items,
        budget_template: budget_template,
        current_budget: current_budget,
        accounts: accounts
    else
      render conn, :show_no_budget_template
    end
  end

  def new(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    categories = categories_list()
    uncategorized = Map.keys(categories)
    |> Enum.find(fn({name, _id}) -> name == "Uncategorized" end)
    categories = Map.delete(categories, uncategorized)
    categories = [{uncategorized, []} | Map.to_list(categories)]

    accounts = Account.by_user_id(user.id) |> Repo.all

    changeset = BudgetTemplate.changeset(%BudgetTemplate{})

    render conn, :new,
      categories: categories,
      changeset: changeset,
      accounts: accounts
  end

  def edit(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    categories = categories_list()
    uncategorized = Map.keys(categories)
    |> Enum.find(fn({name, _id}) -> name == "Uncategorized" end)
    categories = Map.delete(categories, uncategorized)
    categories = [{uncategorized, []} | Map.to_list(categories)]

    accounts = Account.by_user_id(user.id) |> Repo.all
    budget_template = BudgetTemplate.by_user_id(user.id) |> Repo.one
    items = Enum.sort budget_template.items, fn(item_1, item_2) ->
      Decimal.compare(item_1.amount, item_2.amount) == Decimal.new(1)
    end

    changeset = BudgetTemplate.changeset(budget_template)

    render conn, :edit,
      items: items,
      budget_template: budget_template,
      categories: categories,
      changeset: changeset,
      accounts: accounts
  end

  def create(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    budget_template_params = Map.put(params["budget_template"], "user_id", user.id)

    Repo.transaction fn ->
      budget_template = BudgetTemplate.changeset(%BudgetTemplate{}, budget_template_params) |> Repo.insert!

      Enum.each params["budget_items"] || [], fn({category_id, amount}) ->
        BudgetItem.changeset(%BudgetItem{}, %{category_id: category_id, amount: amount, budget_template_id: budget_template.id})
        |> Repo.insert!
      end
    end

    send_resp(conn, 200, "")
  end

  def update(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    budget_template = BudgetTemplate.by_user_id(user.id) |> Repo.one

    Repo.transaction fn ->
      budget_template = BudgetTemplate.changeset(budget_template, params["budget_template"]) |> Repo.update!

      Enum.each params["budget_items"] || [], fn({category_id, amount}) ->
        existing_item = Repo.get_by(BudgetItem, category_id: category_id)

        if existing_item do
          BudgetItem.changeset(existing_item, %{amount: amount})
          |> Repo.update!
        else
          BudgetItem.changeset(%BudgetItem{}, %{category_id: category_id, amount: amount, budget_template_id: budget_template.id})
          |> Repo.insert!
        end
      end
    end

    send_resp(conn, 200, "")
  end

  def apply(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    budget_template = BudgetTemplate.by_user_id(user.id) |> Repo.one
    items = Enum.reduce budget_template.items, %{}, fn(item, acc) ->
      Map.put(acc, item.category_id, item.amount)
    end
    budget_expenses = items_sum(budget_template.items)
    expectation =
      budget_template.income
      |> Decimal.sub(budget_template.goal)
      |> Decimal.sub(budget_expenses)

    changeset = Budget.changeset(%Budget{},
      %{
        accounts: budget_template.accounts,
        goal: budget_template.goal,
        income: budget_template.income,
        expectation: expectation,
        items: items,
        start_date: DateHelper.first_day_of_month(Timex.local),
        end_date: DateHelper.last_day_of_month(Timex.local),
        user_id: user.id
      }
    )

    case Repo.insert(changeset) do
      {:ok, _budget} ->
        send_resp(conn, 200, "")
      {:error, _changeset} ->
        send_resp(conn, 422, "Something went wrong, check server logs")
    end
  end

  defp categories_list do
    categories_dict = Category.visible |> Repo.all

    Enum.reduce(categories_dict, %{}, fn(category, acc) ->
      if is_nil(category.parent_id) do
        sub_categories = Enum.filter(categories_dict, fn(c) -> c.parent_id == category.id end)
        |> Enum.map(fn(sub_category) -> {sub_category.humanized_name, sub_category.id} end)
        Map.put(acc, {category.humanized_name, category.id}, sub_categories)
      else
        acc
      end
    end)
  end

  defp items_sum([]), do: Decimal.new(0)
  defp items_sum([item | items]) do
    Decimal.add(item.amount, items_sum(items))
  end
end
