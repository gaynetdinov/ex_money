defmodule ExMoney.Rule do
  use ExMoney.Web, :model

  alias ExMoney.Rule

  schema "rules" do
    field :type, :string
    field :pattern, :string
    field :target_id, :integer
    field :position, :integer

    belongs_to :account, ExMoney.Account

    timestamps
  end

  @required_fields ~w(type account_id pattern target_id position)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:position,
      name: :rules_position_account_id_type_index,
      message: "has already been taken for given Rule account and Rule type"
    )
    |> validate_number(:position, greater_than: 0)
  end

  def by_account_id(account_id) do
    from r in Rule, where: r.account_id == ^account_id
  end

  def with_account_ordered() do
    from r in Rule,
      preload: [:account],
      order_by: [:account_id, :type, :position]
  end
end
