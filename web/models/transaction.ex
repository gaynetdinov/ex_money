defmodule ExMoney.Transaction do
  use ExMoney.Web, :model

  alias ExMoney.Transaction

  schema "transactions" do
    field :saltedge_transaction_id, :integer
    field :mode, :string
    field :status, :string
    field :made_on, Ecto.Date
    field :amount, :decimal
    field :currency_code, :string
    field :description, :string
    field :category, :string
    field :duplicated, :boolean, default: false
    field :saltedge_account_id, :integer
    field :category_id, :integer

    has_one :transaction_info, ExMoney.TransactionInfo

    timestamps
  end

  @required_fields ~w(
    saltedge_transaction_id
    mode
    status
    made_on
    amount
    currency_code
    description
    category
    duplicated
    saltedge_account_id
  )
  @optional_fields ~w(category_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def by_saltedge_transaction_id(transaction_id) do
    from tr in Transaction, where: tr.saltedge_transaction_id == ^transaction_id, limit: 1
  end

  def recent() do
    from tr in Transaction, limit: 20, order_by: [desc: tr.made_on]
  end
end
