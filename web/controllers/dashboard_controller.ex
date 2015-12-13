defmodule ExMoney.DashboardController do
  use ExMoney.Web, :controller

  alias ExMoney.Repo
  alias ExMoney.Transaction

  alias ExMoney.SessionController
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, %{ on_failure: { SessionController, :new } }

  def overview(conn, _params) do
    recent_transactions = Transaction.recent |> Repo.all
    render conn, "overview.html",
      navigation: "overview",
      topbar: "dashboard",
      recent_transactions: recent_transactions
  end
end
