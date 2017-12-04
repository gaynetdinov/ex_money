defmodule ExMoney.Web.Mobile.BudgetHistoryController do
  use ExMoney.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  alias ExMoney.{Repo, Budget, Account, Category}

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    current_budget = Budget.current_by_user_id(user.id) |> Repo.one
    budgets = Budget.by_user_id(user.id) |> Repo.all()

    budgets = if current_budget do
      Enum.reject(budgets, fn(budget) -> budget.id == current_budget.id end)
    else
      budgets
    end

    render conn, :index,
      current_budget: current_budget,
      budgets: budgets
  end

  def show(conn, %{"id" => id}) do
    budget = Repo.get!(Budget, id)
    accounts =
      Enum.map(budget.accounts, fn(account_id) ->
        Repo.get(Account, account_id).name
      end) |> Enum.join(",")

    items =
      budget.items
      |> Enum.map(fn({id, v}) ->
        name = Repo.get(Category, id).humanized_name
        {amount, _} = Integer.parse(v)
        {name, amount}
      end)
      |> Enum.sort(fn({_name_1, amount_1}, {_name_2, amount_2}) -> amount_1 > amount_2 end)

    budget_expenses =
      items
      |> Enum.map(fn({_, amount}) -> amount end)
      |> Enum.sum

    render conn, :show,
      budget_expenses: budget_expenses,
      budget: budget,
      items: items,
      accounts: accounts
  end
end
