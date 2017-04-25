defmodule ExMoney.Repo.Migrations.AddIncludeToBudgetToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :include_to_budget, :boolean
    end
  end
end
