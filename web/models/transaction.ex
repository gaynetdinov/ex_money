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

    has_one :transaction_info, ExMoney.TransactionInfo
    belongs_to :category, ExMoney.Category
    belongs_to :user, ExMoney.User
    belongs_to :account, ExMoney.Account
    belongs_to :saltedge_account, ExMoney.Account,
      foreign_key: :saltedge_account_id,
      references: :saltedge_account_id

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
    user_id
  )
  @optional_fields ~w(category_id)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def changeset_custom(model, params \\ :empty) do
    model
    |> cast(params, ~w(description amount category_id account_id made_on user_id), ~w())
  end

  def by_user_id(user_id) do
    from tr in Transaction,
      where: tr.user_id == ^user_id
  end

  def by_saltedge_transaction_id(transaction_id) do
    from tr in Transaction,
      where: tr.saltedge_transaction_id == ^transaction_id,
      limit: 1
  end

  def recent() do
    current_date = Timex.Date.local
    from = first_day_of_month(current_date)

    from tr in Transaction,
      where: tr.made_on >= ^from,
      preload: [:transaction_info, :category],
      order_by: [desc: tr.made_on]
  end

  def last_month() do
    current_date = Timex.Date.local
    from = first_day_of_month(current_date)
    to = last_day_of_month(current_date)

    from tr in Transaction,
      where: tr.made_on >= ^from,
      where: tr.made_on <= ^to
  end

  # FIXME cache instead of db
  def newest(saltedge_account_id) do
    from tr in Transaction,
      where: tr.saltedge_account_id == ^saltedge_account_id,
      order_by: [desc: tr.made_on],
      limit: 1
  end

  def newest do
    from tr in Transaction,
      order_by: [desc: tr.made_on],
      limit: 1
  end

  defp first_day_of_month(date) do
    Timex.Date.from({{date.year, date.month, 0}, {0, 0, 0}})
    |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
    |> elem(1)
  end

  defp last_day_of_month(date) do
    days_in_month = Timex.Date.days_in_month(date)

    Timex.Date.from({{date.year, date.month, days_in_month}, {23, 59, 59}})
    |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
    |> elem(1)
  end
end
