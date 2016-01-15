defmodule ExMoney.Repo.Migrations.AddUserIdToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :user_id, :integer
    end
  end
end
