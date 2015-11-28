defmodule ExMoney.DashboardController do
  use ExMoney.Web, :controller

  def main(conn, _params) do
    render conn, "main.html"
  end
end
