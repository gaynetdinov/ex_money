defmodule ExMoney.Repo.Migrations.AddIncomeAndGoalToBudgets do
  use Ecto.Migration

  def change do
    alter table(:budgets) do
      add :income, :decimal
      add :goal, :decimal
    end
  end
end
