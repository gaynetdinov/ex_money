defmodule ExMoney.Repo.Migrations.AddFavouriteTransactions do
  use Ecto.Migration

  def change do
    create table(:favourite_transactions) do
      add :name, :string
      add :made_on, :date
      add :amount, :decimal
      add :currency_code, :string
      add :description, :text
      add :account_id, references(:accounts, on_delete: :delete_all)
      add :category_id, references(:categories, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)
      add :fav, :boolean, default: false

      timestamps
    end
  end
end
