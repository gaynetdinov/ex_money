defmodule ExMoney.Repo.Migrations.AddUniqueIndexToRules do
  use Ecto.Migration

  def change do
    create unique_index(:rules, [:position, :account_id, :type])
  end
end
