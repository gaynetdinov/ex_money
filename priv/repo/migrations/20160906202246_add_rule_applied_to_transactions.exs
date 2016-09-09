defmodule ExMoney.Repo.Migrations.AddRuleAppliedToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :rule_applied, :boolean
    end
  end
end
