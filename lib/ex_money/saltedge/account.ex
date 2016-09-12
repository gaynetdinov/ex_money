defmodule ExMoney.Saltedge.Account do
  require Logger
  alias ExMoney.{Account, Repo}

  def sync(user_id, saltedge_login_id) do
    endpoint = "accounts?login_id=#{saltedge_login_id}"

    case ExMoney.Saltedge.Client.request(:get, endpoint) do
      {:ok, response} ->
        Enum.each response["data"], fn(se_account) ->
          account = se_account
          |> Map.put("saltedge_account_id", se_account["id"])
          |> Map.put("saltedge_login_id", se_account["login_id"])
          |> Map.put("user_id", user_id)
          |> Map.drop(["id", "login_id"])

          existing_account = Account.by_saltedge_account_id(account["saltedge_account_id"])
          |> Repo.one

          persist!(existing_account, account)
        end
      {:error, reason} ->
        Logger.error("Could not sync accounts due to -> #{inspect(reason)}")
    end
  end

  defp persist!(nil, account_params) do
    Account.changeset(%Account{}, account_params) |> Repo.insert!
  end

  defp persist!(existing_account, account_params) do
    Account.update_saltedge_changeset(existing_account, account_params) |> Repo.update!
  end
end
