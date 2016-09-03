defmodule ExMoney.Repo.Migrations.AddAccountsBalanceHistory do
  use Ecto.Migration

  def change do
    create table(:accounts_balance_history) do
      add :account_id, references(:accounts, on_delete: :delete_all)
      add :balance, :decimal

      timestamps
    end
  end
end
