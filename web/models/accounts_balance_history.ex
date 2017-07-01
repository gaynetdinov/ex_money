defmodule ExMoney.AccountsBalanceHistory do
  use ExMoney.Web, :model

  alias ExMoney.AccountsBalanceHistory

  schema "accounts_balance_history" do
    field :balance, :decimal
    belongs_to :account, ExMoney.Account

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(balance account_id)a)
    |> validate_required(~w(balance account_id)a)
  end

  def history(from, to, account_id) do
    {:ok, from} = Ecto.Date.cast(from)
    from = Ecto.DateTime.from_date(from)

    {:ok, to} = Ecto.Date.cast(to)
    to = Ecto.DateTime.from_date(to)

    from h in AccountsBalanceHistory,
      where: h.account_id == ^account_id,
      where: h.inserted_at >= ^from,
      where: h.inserted_at <= ^to
  end
end
