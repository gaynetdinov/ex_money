defmodule ExMoney.TransactionInfo do
  use ExMoney.Web, :model

  alias ExMoney.TransactionInfo

  schema "transactions_info" do
    field :record_number, :string
    field :information, :string
    field :time, :naive_datetime
    field :posting_date, :date
    field :posting_time, :naive_datetime
    field :account_number, :string
    field :original_amount, :decimal
    field :original_currency_code, :string
    field :original_category, :string
    field :original_subcategory, :string
    field :customer_category_code, :string
    field :customer_category_name, :string
    field :tags, {:array, :string}
    field :mcc, :integer
    field :payee, :string
    field :type, :string
    field :check_number, :string
    field :units, :decimal
    field :additional, :string
    field :unit_price, :decimal

    belongs_to :transaction, ExMoney.Transaction

    timestamps()
  end

  @optional_fields ~w(
    transaction_id
    record_number
    information
    time
    posting_date
    posting_time
    account_number
    original_amount
    original_currency_code
    original_category
    original_subcategory
    customer_category_code
    customer_category_name
    tags
    mcc
    payee
    type
    check_number
    units
    additional
    unit_price
  )a

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @optional_fields)
  end

  def by_transaction_id(transaction_id) do
    from tr_info in TransactionInfo,
      where: tr_info.transaction_id == ^transaction_id,
      limit: 1
  end
end
