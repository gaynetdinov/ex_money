defmodule ExMoney.Budget do
  use ExMoney.Web, :model

  alias ExMoney.Budget

  schema "budgets" do
    field :accounts, {:array, :integer}
    field :items, :map
    field :start_date, :date
    field :end_date, :date
    field :income, :decimal
    field :goal, :decimal
    field :expectation, :decimal

    belongs_to :user, ExMoney.User

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(accounts items start_date end_date user_id income goal expectation)a)
    |> validate_required(~w(accounts start_date end_date user_id)a)
  end

  def by_user_id(user_id) do
    from bt in Budget,
      where: bt.user_id == ^user_id
  end

  def current_by_user_id(user_id) do
    from b in Budget,
      where: b.user_id == ^user_id,
      where: b.start_date <= ^Timex.local,
      where: b.end_date >= ^Timex.local
  end
end
