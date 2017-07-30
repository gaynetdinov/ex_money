defmodule ExMoney.Repo.Migrations.AddBudgets do
  use Ecto.Migration

  def change do
    create table(:budgets) do
      add :start_date, :date
      add :end_date, :date
      add :items, :map, null: false
      add :accounts, {:array, :integer}, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
  end
end
