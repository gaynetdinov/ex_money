defmodule ExMoney.Repo.Migrations.AddShowOnDashabordToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :show_on_dashboard, :boolean, default: true
    end
  end
end
