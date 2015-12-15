defmodule ExMoney.Category do
  use ExMoney.Web, :model

  alias ExMoney.Category

  schema "categories" do
    field :name, :string
    field :parent_id, :integer

    timestamps

    has_many :transactions, ExMoney.Transaction
  end

  @required_fields ~w(name)
  @optional_fields ~w(parent_id)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def by_name(name) do
    from c in Category, where: c.name == ^name, limit: 1
  end
end
