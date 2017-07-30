defmodule ExMoney.Repo.Migrations.AddBudgetItems do
  use Ecto.Migration

  def change do
    create table(:budget_items) do
      add :budget_template_id, references(:budget_templates, on_delete: :delete_all)
      add :category_id, references(:categories, on_delete: :delete_all)
      add :amount, :decimal

      timestamps()
    end
  end
end
