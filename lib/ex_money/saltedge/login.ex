defmodule ExMoney.Saltedge.Login do
  alias ExMoney.Login
  alias ExMoney.Repo

  def sync(user_id) do
    logins = ExMoney.Saltedge.Client.request(:get, "logins")["data"]

    store_or_update_logins(logins, user_id)
  end

  def sync(user_id, login_id) do
    login_url = "logins/#{login_id}"
    login = ExMoney.Saltedge.Client.request(:get, login_url)["data"]

    store_or_update_logins([login], user_id)
  end

  defp store_or_update_logins(logins, user_id) do
    Enum.each(logins, fn(login) ->
      login = Map.put(login, "saltedge_login_id", login["id"])
      login = Map.drop(login, ["id"])
      login = Map.put(login, "user_id", user_id)
      existing_login = Login.by_saltedge_login_id(login["saltedge_login_id"]) |> Repo.one

      if existing_login do
        changeset = Login.changeset(existing_login, login)
        Repo.update!(changeset)
      else
        changeset = Login.changeset(%Login{}, login)
        Repo.insert!(changeset)
      end
    end)
  end
end
