defmodule ExMoney.Repo.Migrations.AddAccountIdToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :account_id, :integer
    end
  end
end
