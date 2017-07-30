defmodule ExMoney.Repo.Migrations.AddExpectationToBudgets do
  use Ecto.Migration

  def change do
    alter table(:budgets) do
      add :expectation, :decimal
    end
  end
end
