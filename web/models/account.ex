defmodule ExMoney.Account do
  use ExMoney.Web, :model

  schema "accounts" do
    field :saltedge_account_id, :integer
    field :name, :string
    field :nature, :string
    field :balance, :decimal
    field :currency_code, :string
    field :currency_label, :string
    field :show_on_dashboard, :boolean

    belongs_to :login, ExMoney.Login,
      foreign_key: :saltedge_login_id,
      references: :saltedge_login_id
    belongs_to :user, ExMoney.User
    has_many :rules, ExMoney.Rule
    has_many :transactions, ExMoney.Transaction,
      on_delete: :delete_all,
      foreign_key: :saltedge_account_id,
      references: :saltedge_account_id

    timestamps
  end

  @required_fields ~w(name nature balance currency_code saltedge_login_id saltedge_account_id user_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def changeset_for_custom_account(model, params \\ :empty) do
    model
    |> cast(params, ~w(name balance currency_code user_id), ~w())
  end

  def update_custom_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(), ~w(name balance currency_code currency_label show_on_dashboard))
  end

  def update_saltedge_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(balance), ~w())
  end

  def by_saltedge_login_id(login_ids) do
    from l in ExMoney.Account, where: l.saltedge_login_id in ^login_ids
  end

  def by_saltedge_account_id(account_id) do
    from l in ExMoney.Account, where: l.saltedge_account_id == ^account_id, limit: 1
  end

  def show_on_dashboard() do
    from acc in ExMoney.Account, where: acc.show_on_dashboard == true
  end

  def by_user_id(user_id) do
    from a in ExMoney.Account, where: a.user_id == ^user_id
  end

  def only_custom do
    from a in ExMoney.Account,
      where: is_nil(a.saltedge_account_id),
      select: {a.name, a.id},
      order_by: a.name
  end

  def only_saltedge do
    from a in ExMoney.Account,
      where: not is_nil(a.saltedge_account_id),
      select: {a.name, a.id},
      order_by: a.name
  end
end
