defmodule ExMoney.Repo.Migrations.AddLoginLogs do
  use Ecto.Migration

  def change do
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
