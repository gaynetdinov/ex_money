defmodule ExMoney.SyncLogApi.SyncLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sync_log" do
    field :uuid, :string
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
    |> generate_uuid()
  end

  defp generate_uuid(changeset) do
    Ecto.Changeset.put_change(changeset, :uuid, Ecto.UUID.generate())
  end
end
