defmodule ExMoney.Repo.Migrations.AddLastRefreshedAt do
  use Ecto.Migration

  def change do
    alter table(:logins) do
      add :last_refreshed_at, :datetime
    end
  end
end
