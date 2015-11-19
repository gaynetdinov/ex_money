defmodule ExMoney.PageController do
  use ExMoney.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
