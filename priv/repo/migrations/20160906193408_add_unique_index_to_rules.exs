defmodule ExMoney.Repo.Migrations.AddUniqueIndexToRules do
  use Ecto.Migration

  def change do
    rename table(:rules), :position, to: :priority

    create unique_index(:rules, [:priority, :account_id])
  end
end
