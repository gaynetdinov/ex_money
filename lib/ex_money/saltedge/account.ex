defmodule ExMoney.Saltedge.Account do
  alias ExMoney.Account
  alias ExMoney.Repo

  def sync(saltedge_login_ids) do
    accounts = ExMoney.Saltedge.Client.request(:get, "accounts")["data"]
    |> Enum.reject(fn(account) -> not Enum.member?(saltedge_login_ids, account["login_id"]) end)

    Enum.each(accounts, fn(account) ->
      account = Map.put(account, "saltedge_account_id", account["id"])
      account = Map.drop(account, ["id"])
      existing_account = Account.by_saltedge_account_id(account["saltedge_account_id"]) |> Repo.one

      if !existing_account do
        account = Map.put(account, "saltedge_login_id", account["login_id"])
        changeset = Account.changeset(%Account{}, account)
        Repo.insert!(changeset)
      end
    end)
  end
end
