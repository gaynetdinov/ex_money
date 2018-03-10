defmodule ExMoney.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false
  alias ExMoney.Repo

  alias ExMoney.Transactions.Transaction

  def changeset(transaction) do
    Transaction.changeset(transaction)
  end

  def changeset_custom() do
    Transaction.changeset_custom(%Transaction{})
  end

  def update_changeset(transaction) do
    Transaction.update_changeset(transaction)
  end

  def get_transaction(id) do
    Repo.get(Transaction, id)
  end

  def get_transaction!(id) do
    Repo.get!(Transaction, id)
  end

  def get_transaction_by(params) do
    Repo.get_by(Transaction, params)
  end

  def get_transaction_by!(params) do
    Repo.get_by!(Transaction, params)
  end

  # FIXME
  def delete_transaction!(id) do
    Repo.get!(Transaction, id) |> Repo.delete!
  end

  def get_transaction_with_includes!(id, includes) do
    query = from tr in Transaction, where: tr.id == ^id, preload: ^includes

    Repo.one(query)
  end

  def create_transaction(attributes) do
    Transaction.changeset(%Transaction{}, attributes)
    |> Repo.insert()
  end

  def create_transaction!(attributes) do
    Transaction.changeset(%Transaction{}, attributes)
    |> Repo.insert!()
  end

  def create_custom_transaction!(attributes) do
    Transaction.changeset_custom(%Transaction{}, attributes)
    |> Repo.insert!()
  end

  def update_transaction(transaction, attributes) do
    Transaction.update_changeset(transaction, attributes)
    |> Repo.update()
  end

  def update_transaction!(transaction, attributes) do
    Transaction.update_changeset(transaction, attributes)
    |> Repo.update!()
  end

  def search(account_id, pattern) do
    query =
      from tr in Transaction,
        where: tr.account_id == ^account_id,
        where: tr.rule_applied == false,
        where: fragment("description ~* ?", ^pattern) or fragment("extra->>'payee' ~* ?", ^pattern)

    Repo.all(query)
  end

  def by_user_id(user_id) do
    from tr in Transaction,
      where: tr.user_id == ^user_id
  end

  def by_saltedge_transaction_id(transaction_id) do
    query =
      from tr in Transaction,
        where: tr.saltedge_transaction_id == ^transaction_id,
        limit: 1

    Repo.one(query)
  end

  def recent(user_id) do
    current_date = Timex.local
    from = Timex.shift(current_date, days: -15)

    query =
      from tr in Transaction,
        where: tr.made_on >= ^from,
        where: tr.user_id == ^user_id,
        preload: [:category, :account],
        order_by: [desc: tr.inserted_at]

    Repo.all(query)
  end

  def new_since(time, account_id) do
    query =
      from tr in Transaction,
        where: tr.inserted_at >= ^time,
        where: tr.account_id == ^account_id

    Repo.all(query)
  end

  def by_month(account_ids, from, to) when is_list(account_ids) do
    from tr in Transaction,
      preload: [:account, :category],
      where: tr.made_on >= ^from,
      where: tr.made_on <= ^to,
      where: tr.account_id in ^account_ids
  end

  def by_month(account_id, from, to) do
    from tr in Transaction,
      where: tr.made_on >= ^from,
      where: tr.made_on <= ^to,
      where: tr.account_id == ^account_id
  end

  def expenses_by_month_by_category(account_id, from, to, category_ids) do
    by_month(account_id, from, to)
    |> where([tr], tr.amount < 0)
    |> where([tr], tr.category_id in ^(category_ids))
    |> preload([:category, :account])
    |> Repo.all()
  end

  def by_month_by_category(account_id, from, to, category_ids) do
    by_month(account_id, from, to)
    |> where([tr], tr.category_id in ^(category_ids))
    |> preload([:category, :account])
    |> Repo.all()
  end

  def expenses_by_month(account_id, from, to) do
    query =
      from tr in by_month(account_id, from, to),
        join: c in assoc(tr, :category),
        where: tr.amount < 0,
        where: c.name != "withdraw",
        preload: [:category, :account]

    Repo.all(query)
  end

  def income_by_month_by_category(account_id, from, to, category_ids) do
    by_month(account_id, from, to)
    |> where([tr], tr.amount > 0 )
    |> where([tr], tr.category_id in ^(category_ids))
    |> preload([:category, :account])
    |> Repo.all()
  end

  def income_by_month(account_id, from ,to) do
    query =
      from tr in by_month(account_id, from, to),
        join: c in assoc(tr, :category),
        where: tr.amount > 0,
        where: c.name != "withdraw",
        preload: [:category, :account]

    Repo.all(query)
  end

  def group_by_month_by_category_without_withdraw(account_ids, from, to) do
    query =
      from tr in Transaction,
        join: c in assoc(tr, :category),
        where: c.name != "withdraw",
        where: tr.made_on >= ^from,
        where: tr.made_on <= ^to,
        where: tr.account_id in ^account_ids,
        where: tr.amount < 0,
        group_by: [c.id],
        select: {c, sum(tr.amount)}

    Repo.all(query)
  end

  def group_by_month_by_category(account_id, from, to) do
    query =
      from tr in Transaction,
        join: c in assoc(tr, :category),
        where: tr.made_on >= ^from,
        where: tr.made_on <= ^to,
        where: tr.account_id == ^account_id,
        where: tr.amount < 0,
        group_by: [c.id],
        select: {c, sum(tr.amount)}

    Repo.all(query)
  end

  # FIXME cache instead of db
  def newest(saltedge_account_id) do
    query =
      from tr in Transaction,
        where: tr.saltedge_account_id == ^saltedge_account_id,
        order_by: [desc: tr.made_on],
        limit: 1

    Repo.one(query)
  end

  def newest do
    from tr in Transaction,
      order_by: [desc: tr.made_on],
      limit: 1
  end
end
