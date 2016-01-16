defmodule ExMoney.Repo.Migrations.AddUserIdToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :user_id, :integer
    end
  end
end
