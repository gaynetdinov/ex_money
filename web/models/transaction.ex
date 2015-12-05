defmodule ExMoney.Transaction do
  use ExMoney.Web, :model

  schema "transactions" do
    field :saltedge_transaction_id, :integer
    field :mode, :string
    field :status, :string
    field :made_on, Ecto.DateTime
    field :amount, :decimal
    field :currency_code, :string
    field :description, :string
    field :category, :string
    field :duplicated, :boolean, default: false
    field :saltedge_account_id, :integer
    field :category_id, :integer

    timestamps
  end

  @required_fields ~w(saltedge_transaction_id mode status made_on amount currency_code description category duplicated saltedge_account_id category_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
