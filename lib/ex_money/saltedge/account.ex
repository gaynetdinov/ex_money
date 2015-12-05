defmodule ExMoney.Saltedge.Account do
  alias ExMoney.Account
  alias ExMoney.Repo

  def sync(saltedge_login_id) do
    accounts = ExMoney.Saltedge.Client.request(:get, "accounts")

    Enum.each(accounts["data"], fn(account) ->
      account = Map.put(account, "saltedge_account_id", account["id"])
      account = Map.drop(account, ["id"])
      existing_account = Account.by_saltedge_account_id(account["saltedge_account_id"]) |> Repo.one

      if !existing_account do
        account = Map.put(account, "saltedge_login_id", saltedge_login_id)
        changeset = Account.changeset(%Account{}, account)
        Repo.insert!(changeset)
      end
    end)
  end
end
