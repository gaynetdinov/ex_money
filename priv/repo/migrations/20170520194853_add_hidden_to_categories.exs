defmodule ExMoney.Repo.Migrations.AddHiddenToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :hidden, :boolean, default: false
    end
  end
end
