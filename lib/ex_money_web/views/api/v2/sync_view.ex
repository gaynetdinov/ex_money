defmodule ExMoney.Web.Api.V2.SyncView do
  use ExMoney.Web, :view

  alias ExMoney.Web.Api.V2.SyncView

  def render("index.json", %{entries: entries}) do
    render_many(entries, SyncView, "entry.json")
  end

  def render("entry.json", %{sync: entry}) do
    %{
      uid: entry.uid,
      entity: entry.entity,
      action: entry.action,
      payload: entry.payload
     }
  end
end
