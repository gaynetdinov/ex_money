defmodule ExMoney.Web.Api.V2.SyncController do
  use ExMoney.Web, :controller

  alias ExMoney.SyncLogApi

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.ApiUnauthenticated

  def index(conn, params) do
    per_page = params["per_page"] || 20

    entries = SyncLogApi.get(per_page)

    render conn, :index, entries: entries
  end
end
