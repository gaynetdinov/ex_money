defmodule ExMoney.SyncLogApi do
  @moduledoc """
  Api functions to sync things.
  """

  import Ecto.Query, warn: false
  alias ExMoney.Repo

  alias ExMoney.SyncLogApi.SyncLog

  def store(entity, action, payload) do
    %SyncLog{}
    |> SyncLog.changeset(%{action: action, entity: entity, payload: payload})
    |> Repo.insert
  end

  def get(per_page) do
    query =
      from sl in SyncLog,
        where: is_nil(sl.synced_at),
        order_by: [asc: sl.inserted_at],
        limit: ^per_page

    Repo.all(query)
  end

  def get_entry!(uuid) do
    Repo.get_by!(SyncLog, uuid: uuid)
  end

  def mark_synced!(entry) do
    SyncLog.changeset(entry, %{synced_at: DateTime.utc_now()})
    |> Repo.update!
  end
end
