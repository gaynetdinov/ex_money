defmodule ExMoney.Repo.Migrations.AddFetchAllTriedToLogins do
  use Ecto.Migration

  def change do
    alter table(:logins) do
      add :fetch_all_tried, :boolean, default: false
    end
  end
end
