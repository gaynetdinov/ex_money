defmodule ExMoney.Web.Mobile.LoggedInController do
  use ExMoney.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated

  def index(conn, _params) do
    send_resp(conn, 200, "")
  end
end
