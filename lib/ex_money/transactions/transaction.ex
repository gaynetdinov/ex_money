defmodule ExMoney.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :saltedge_transaction_id, :integer
    field :mode, :string
    field :status, :string
    field :made_on, :date
    field :amount, :decimal
    field :currency_code, :string
    field :description, :string
    field :duplicated, :boolean, default: false
    field :rule_applied, :boolean, default: false
    field :extra, :map
    field :uuid, :string

    belongs_to :category, ExMoney.Category
    belongs_to :user, ExMoney.User
    belongs_to :account, ExMoney.Account
    belongs_to :saltedge_account, ExMoney.Account,
      foreign_key: :saltedge_account_id,
      references: :saltedge_account_id

    timestamps()
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
    account_id
    user_id
  )a
  @optional_fields ~w(category_id rule_applied extra)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> generate_uuid()
  end

  def changeset_custom(model, params \\ %{}) do
    model
    |> cast(params, ~w(amount category_id account_id made_on user_id description extra)a)
    |> validate_required(~w(amount category_id account_id made_on user_id)a)
    |> negate_amount(params)
    |> generate_uuid()
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(category_id description rule_applied extra)a)
  end

  def negate_amount(changeset, params) when params == %{}, do: changeset
  def negate_amount(changeset, %{"type" => "income"}), do: changeset

  def negate_amount(changeset, %{"type" => "expense"}) do
    case Ecto.Changeset.fetch_change(changeset, :amount) do
      {:ok, amount} ->
        Ecto.Changeset.put_change(changeset, :amount, Decimal.mult(amount, Decimal.new(-1)))
      :error -> changeset
    end
  end

  defp generate_uuid(changeset) do
    Ecto.Changeset.put_change(changeset, :uuid, Ecto.UUID.generate())
  end
end
