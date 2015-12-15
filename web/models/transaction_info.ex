defmodule ExMoney.TransactionInfo do
  use ExMoney.Web, :model

  schema "transactions_info" do
    field :record_number, :string
    field :information, :string
    field :time, Ecto.DateTime
    field :posting_date, Ecto.Date
    field :posting_time, Ecto.DateTime
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

    timestamps
  end

  @required_fields ~w()
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
  )

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
