defmodule ExMoney.Accounts.BalanceHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts_balance_history" do
    field :state, :map

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(state)a)
    |> validate_required(~w(state)a)
  end
end
