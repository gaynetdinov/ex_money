defmodule ExMoney.Repo.Migrations.CreateTransaction do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :saltedge_transaction_id, :integer
      add :mode, :string
      add :status, :string
      add :made_on, :date
      add :amount, :decimal
      add :currency_code, :string
      add :description, :text
      add :category, :string
      add :duplicated, :boolean, default: false
      add :saltedge_account_id, references(:accounts, column: :saltedge_account_id, on_delete: :delete_all)
      add :category_id, :integer

      timestamps
    end

  end
end
