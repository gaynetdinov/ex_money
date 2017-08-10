defmodule ExMoney.Web.Mobile.SettingController do
  use ExMoney.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def index(conn, _params) do
    render conn, :index
  end
end
