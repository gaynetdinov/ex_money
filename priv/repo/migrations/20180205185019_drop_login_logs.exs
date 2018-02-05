defmodule ExMoney.Repo.Migrations.DropLoginLogs do
  use Ecto.Migration

  def up do
    drop table(:login_logs)
  end

  def down do
    create table(:login_logs) do
      add :login_id, references(:logins, on_delete: :delete_all)
      add :callback, :string
      add :event, :string
      add :description, :string
      add :params, :map

      timestamps
    end
  end
end
