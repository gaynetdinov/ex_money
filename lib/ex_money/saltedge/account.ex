defmodule ExMoney.Saltedge.Account do
  alias ExMoney.{Account, Repo}

  def sync(user_id, saltedge_login_id) do
    # By some reason there is no way to fetch only login's accounts,
    # so fetch all and process only necessary ones.
    accounts = ExMoney.Saltedge.Client.request(:get, "accounts")["data"]
    |> Enum.reject(fn(account) -> saltedge_login_id != account["login_id"] end)

    Enum.each(accounts, fn(account) ->
      account = Map.put(account, "saltedge_account_id", account["id"])
      account = Map.put(account, "saltedge_login_id", account["login_id"])
      account = Map.put(account, "user_id", user_id)
      account = Map.drop(account, ["id", "login_id"])
      existing_account = Account.by_saltedge_account_id(account["saltedge_account_id"]) |> Repo.one

      persist!(existing_account, account)
    end)
  end

  defp persist!(nil, account_params) do
    Account.changeset(%Account{}, account_params) |> Repo.insert!
  end

  defp persist!(existing_account, account_params) do
    Account.changeset(existing_account, account_params) |> Repo.update!
  end
end
