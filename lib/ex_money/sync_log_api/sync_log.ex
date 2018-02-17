defmodule ExMoney.SyncLogApi.SyncLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sync_log" do
    field :uid, :string
    field :action, :string
    field :entity, :string
    field :payload, :map
    field :synced_at, :naive_datetime

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:action, :entity, :payload, :synced_at])
    |> validate_required([:action, :entity, :payload])
    |> generate_uid()
  end

  defp generate_uid(changeset) do
    Ecto.Changeset.put_change(changeset, :uid, Ecto.UUID.generate())
  end
end
