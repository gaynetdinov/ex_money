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
    field :duplicated, :boolean, default: false
    field :saltedge_account_id, :integer

    has_one :transaction_info, ExMoney.TransactionInfo
    belongs_to :category, ExMoney.Category

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
    duplicated
    saltedge_account_id
  )
  @optional_fields ~w(category_id)

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

  # FIXME cache instead of db
  def oldest(saltedge_account_id) do
    from tr in Transaction,
    where: tr.saltedge_account_id == ^saltedge_account_id,
    order_by: [desc: tr.saltedge_transaction_id],
    limit: 1
  end

  def oldest do
    from tr in Transaction,
    order_by: [asc: tr.saltedge_transaction_id],
    limit: 1
  end
end
