defmodule ExMoney.Account do
  use ExMoney.Web, :model

  alias ExMoney.Account

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

    timestamps()
  end

  @required_fields ~w(name nature balance currency_code saltedge_login_id saltedge_account_id user_id)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  def changeset_for_custom_account(model, params \\ %{}) do
    model
    |> cast(params, ~w(name balance currency_code user_id)a)
    |> validate_required(~w(name balance currency_code user_id)a)
  end

  def update_custom_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name balance currency_code currency_label show_on_dashboard)a)
  end

  def update_saltedge_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(balance)a)
    |> validate_required(~w(balance)a)
  end

  def by_saltedge_login_id(login_ids) do
    from l in Account, where: l.saltedge_login_id in ^login_ids
  end

  def by_saltedge_account_id(account_id) do
    from l in Account, where: l.saltedge_account_id == ^account_id, limit: 1
  end

  def by_ids(ids) do
    from a in Account, where: a.id in ^(ids)
  end

  def show_on_dashboard do
    from acc in Account,
      where: acc.show_on_dashboard == true,
      order_by: acc.name
  end

  def by_user_id(user_id) do
    from a in Account, where: a.user_id == ^user_id
  end

  def only_custom do
    from a in Account,
      where: is_nil(a.saltedge_account_id),
      select: {a.name, a.id},
      order_by: a.name
  end

  def only_saltedge do
    from a in Account,
      where: not is_nil(a.saltedge_account_id),
      select: {a.name, a.id},
      order_by: a.name
  end

  def by_id_with_login(account_id) do
    from a in Account,
      where: a.id == ^account_id,
      preload: [:login]
  end
end
