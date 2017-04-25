defmodule ExMoney.Mobile.Setting.BudgetController do
  use ExMoney.Web, :controller

  alias ExMoney.{Account, Repo}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def index(conn, _params) do
    accounts = Repo.all(Account)
    render conn, :index, accounts: accounts
  end

  def setup(conn, params) do
    account = Repo.get!(Account, params["account_id"])

    budget_accounts = Account.in_budget |> Repo.all

    if budget_accounts == [] or List.first(budget_accounts).currency_code == account.currency_code do
      update_params = %{include_to_budget: !account.include_to_budget}
      Account.update_custom_changeset(account, update_params)
      |> Repo.update!

      send_resp(conn, 200, Poison.encode!(update_params))
    else
      msg = Poison.encode!(%{msg: "All budget accounts must have the same currency"})
      send_resp(conn, 422, msg)
    end
  end
end
