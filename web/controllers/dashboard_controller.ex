defmodule ExMoney.DashboardController do
  use ExMoney.Web, :controller

  alias ExMoney.Login
  alias ExMoney.Repo

  alias ExMoney.SessionController
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, %{ on_failure: { SessionController, :new } }

  def overview(conn, _params) do
    render conn, "overview.html", navigation: "overview", topbar: "dashboard"
  end
end
