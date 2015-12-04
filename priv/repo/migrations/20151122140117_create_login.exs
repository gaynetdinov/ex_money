defmodule ExMoney.Repo.Migrations.CreateLogin do
  use Ecto.Migration

  def change do
    create table(:logins) do
      add :user_id, references(:users)
      add :saltedge_login_id, :integer
      add :secret, :string
      add :finished, :boolean, default: false
      add :finished_recent, :boolean, default: false
      add :partial, :boolean, default: false
      add :automatic_fetch, :boolean, default: false
      add :interactive, :boolean, default: false
      add :provider_score, :string
      add :provider_name, :string
      add :last_fail_at, :datetime
      add :last_fail_message, :string
      add :last_fail_error_class, :string
      add :last_request_at, :datetime
      add :last_success_at, :datetime
      add :status, :string
      add :country_code, :string
      add :interactive_html, :string
      add :interactive_fields_names, {:array, :string}
      add :stage, :string
      add :store_credentials, :boolean, default: false

      timestamps
    end

    create index(:logins, [:saltedge_login_id], unique: true)
  end
end
