defmodule ExMoney.Web.Mobile.StartController do
  use ExMoney.Web, :controller

  plug :put_layout, "mobile.html"

  def index(conn, _params) do
    render conn, :index
  end
end
