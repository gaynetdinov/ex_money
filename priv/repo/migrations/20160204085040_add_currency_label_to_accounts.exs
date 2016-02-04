defmodule ExMoney.Repo.Migrations.AddCurrencyLabelToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :currency_label, :string
    end
  end
end
