defmodule ExMoney.Repo.Migrations.AddColorToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :css_color, :string
    end
  end
end
