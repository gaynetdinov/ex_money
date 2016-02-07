defmodule ExMoney.Repo.Migrations.AddLastLoginAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_login_at, :datetime
    end
  end
end
