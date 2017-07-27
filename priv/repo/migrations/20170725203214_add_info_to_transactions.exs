defmodule ExMoney.Repo.Migrations.AddInfoToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :extra, :map
    end
  end
end
