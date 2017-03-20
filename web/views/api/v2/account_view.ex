defmodule ExMoney.Api.V2.AccountView do
  use ExMoney.Web, :view

  def render("index.json", %{accounts: accounts}) do
    render_many(accounts, ExMoney.Api.V2.AccountView, "account.json")
  end

  def render("account.json", %{account: account}) do
    %{
       id: account.id,
       name: account.name,
       balance: account.balance,
       currency_code: account.currency_code,
       show_on_dashboard: account.show_on_dashboard,
       saltedge_account_id: account.saltedge_account_id
     }
  end
end
