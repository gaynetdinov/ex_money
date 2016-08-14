defmodule ExMoney.Rule do
  use ExMoney.Web, :model

  alias ExMoney.Rule

  schema "rules" do
    field :type, :string
    field :pattern, :string
    field :target_id, :integer

    belongs_to :account, ExMoney.Account

    timestamps
  end

  @required_fields ~w(type account_id pattern target_id)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def by_account_id(account_id) do
    from r in Rule, where: r.account_id == ^account_id
  end
end
