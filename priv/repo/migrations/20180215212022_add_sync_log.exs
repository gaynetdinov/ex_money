defmodule ExMoney.Repo.Migrations.AddSyncLog do
  use Ecto.Migration

  def change do
    create table(:sync_log) do
      add :uid, :string
      add :action, :string, null: false
      add :entity, :string, null: false
      add :payload, :map, null: false
      add :synced_at, :naive_datetime

      timestamps()
    end
  end
end
