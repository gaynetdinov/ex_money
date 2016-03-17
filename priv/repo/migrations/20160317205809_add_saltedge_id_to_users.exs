defmodule ExMoney.Repo.Migrations.AddSaltedgeIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :saltedge_id, :integer
    end
  end
end
