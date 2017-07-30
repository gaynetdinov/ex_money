defmodule ExMoney.Repo.Migrations.AddIncomeAndGoalToBudgetTemplates do
  use Ecto.Migration

  def change do
    alter table(:budget_templates) do
      add :income, :decimal
      add :goal, :decimal
    end
  end
end
