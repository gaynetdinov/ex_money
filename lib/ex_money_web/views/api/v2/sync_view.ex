defmodule ExMoney.Web.Api.V2.SyncView do
  use ExMoney.Web, :view

  alias ExMoney.Web.Api.V2.SyncView

  def render("index.json", %{entries: entries}) do
    render_many(entries, SyncView, "entry.json")
  end

  def render("entry.json", %{sync: entry}) do
    %{
      uuid: entry.uuid,
      entity: entry.entity,
      action: entry.action,
      payload: payload(entry.entity, entry.payload)
     }
  end

  defp payload(entity, %{"amount" => amount} = payload) when entity == "Transaction" do
    Map.put(payload, "amount_millicents", ExMoney.Money.to_millicents(amount))
  end

  defp payload(_entity, payload), do: payload
end
