defmodule ExMoney.Repo.Migrations.CreateTransactionInfo do
  use Ecto.Migration

  def change do
    create table(:transactions_info) do
      add :record_number, :string
      add :information, :text
      add :time, :datetime
      add :posting_date, :date
      add :posting_time, :datetime
      add :account_number, :string
      add :original_amount, :decimal
      add :original_currency_code, :string
      add :original_category, :string
      add :original_subcategory, :string
      add :customer_category_code, :string
      add :customer_category_name, :string
      add :tags, {:array, :string}
      add :mcc, :integer
      add :payee, :string
      add :type, :string
      add :check_number, :string
      add :units, :decimal
      add :additional, :text
      add :unit_price, :decimal

      add :transaction_id, references(:transactions, on_delete: :delete_all)

      timestamps
    end

  end
end
