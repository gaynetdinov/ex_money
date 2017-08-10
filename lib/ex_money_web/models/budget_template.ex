defmodule ExMoney.BudgetTemplate do
  use ExMoney.Web, :model

  alias ExMoney.BudgetTemplate

  schema "budget_templates" do
    field :name, :string
    field :accounts, {:array, :integer}
    field :income, :decimal
    field :goal, :decimal

    belongs_to :user, ExMoney.User
    has_many :items, ExMoney.BudgetItem, foreign_key: :budget_template_id

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(accounts user_id goal income)a)
    |> validate_required(~w(accounts user_id)a)
  end

  def by_user_id(user_id) do
    from bt in BudgetTemplate,
      where: bt.user_id == ^user_id,
      preload: [items: :category]
  end
end
