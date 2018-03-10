defmodule ExMoney.Repo.Migrations.RenameUidToUuid do
  use Ecto.Migration

  def change do
    rename table(:sync_log), :uid, to: :uuid
    rename table(:transactions), :uid, to: :uuid
  end
end
