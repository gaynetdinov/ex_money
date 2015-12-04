defmodule ExMoney.Account do
  use ExMoney.Web, :model

  schema "accounts" do
    field :saltedge_account_id, :integer
    field :name, :string
    field :nature, :string
    field :balance, :decimal
    field :currency_code, :string

    belongs_to :login, ExMoney.Login, foreign_key: :saltedge_login_id

    timestamps
  end

  @required_fields ~w(name nature balance currency_code saltedge_login_id saltedge_account_id)
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

  def by_saltedge_login_id(login_id) do
    from l in ExMoney.Account, where: l.saltedge_login_id == ^login_id, limit: 1
  end

  def by_saltedge_account_id(account_id) do
    from l in ExMoney.Account, where: l.saltedge_account_id == ^account_id, limit: 1
  end
end
