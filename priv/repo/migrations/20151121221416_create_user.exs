defmodule ExMoney.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :encrypted_password, :string
      add :saltedge_customer_id, :string
      add :saltedge_token, :string

      timestamps
    end

  end
end
