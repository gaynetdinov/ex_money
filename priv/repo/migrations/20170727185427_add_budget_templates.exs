defmodule ExMoney.Repo.Migrations.AddBudgetTemplates do
  use Ecto.Migration

  def change do
    create table(:budget_templates) do
      add :name, :string
      add :user_id, references(:users, on_delete: :delete_all)
      add :accounts, {:array, :integer}, null: false

      timestamps()
    end
  end
end
