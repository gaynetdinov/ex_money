defmodule ExMoney.Rule do
  use ExMoney.Web, :model

  alias ExMoney.Rule

  schema "rules" do
    field :type, :string
    field :pattern, :string
    field :target_id, :integer
    field :priority, :integer

    belongs_to :account, ExMoney.Account

    timestamps()
  end

  @required_fields ~w(type account_id pattern target_id priority)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:priority,
      name: :rules_priority_account_id_index,
      message: "has already been taken for given account"
    )
    |> validate_number(:priority, greater_than: 0)
  end

  def by_account_id(account_id) do
    from r in Rule, where: r.account_id == ^account_id
  end

  def with_account_ordered() do
    from r in Rule,
      preload: [:account],
      order_by: [:account_id, :priority]
  end
end
