defmodule ExMoney.Web.Mobile.Setting.BudgetItemController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, BudgetItem}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def delete(conn, %{"id" => id}) do
    budget_item = Repo.get!(BudgetItem, id)

    Repo.delete!(budget_item)

    put_resp_content_type(conn, "application/json")
    |> send_resp(200, Poison.encode!(%{}))
  end
end
