defmodule ExMoney.Repo.Migrations.AddUidToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :uid, :string
    end
  end
end
