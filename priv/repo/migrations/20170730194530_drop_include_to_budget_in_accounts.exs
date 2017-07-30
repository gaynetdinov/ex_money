defmodule ExMoney.Repo.Migrations.DropIncludeToBudgetInAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      remove :include_to_budget
    end
  end
end
