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
    {:ok, from} = Date.from_iso8601(from)
    erl_from = Date.to_erl(from)
    {:ok, naive_from} = NaiveDateTime.from_erl({erl_from, {0, 0, 0}})

    {:ok, to} = Date.from_iso8601(to)
    erl_to = Date.to_erl(to)
    {:ok, naive_to} = NaiveDateTime.from_erl({erl_to, {0, 0, 0}})

    from h in AccountsBalanceHistory,
      where: h.account_id == ^account_id,
      where: h.inserted_at >= ^naive_from,
      where: h.inserted_at <= ^naive_to
  end
end
