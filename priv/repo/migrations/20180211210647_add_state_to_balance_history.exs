defmodule ExMoney.Repo.Migrations.AddStateToBalanceHistory do
  use Ecto.Migration

  def change do
    alter table(:accounts_balance_history) do
      add :state, :map
    end
  end
end
