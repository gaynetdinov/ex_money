defmodule ExMoney.Repo.Migrations.AddHumanizedNameToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :humanized_name, :string
    end
  end
end
