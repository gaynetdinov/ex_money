defmodule ExMoney.BudgetItem do
  use ExMoney.Web, :model

  schema "budget_items" do
    field :amount, :decimal

    belongs_to :category, ExMoney.Category
    belongs_to :budget_template, ExMoney.BudgetTemplate

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(category_id amount budget_template_id)a)
  end
end
