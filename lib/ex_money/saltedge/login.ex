defmodule ExMoney.Saltedge.Login do
  alias ExMoney.Login
  alias ExMoney.Repo

  def sync(user_id) do
    logins = ExMoney.Saltedge.Client.request(:get, "logins")

    Enum.each(logins["data"], fn(login) ->
      login = Map.put(login, "saltedge_login_id", login["id"])
      login = Map.drop(login, ["id"])
      existing_login = Login.by_saltedge_login_id(login["saltedge_login_id"]) |> Repo.one

      if !existing_login do
        login = Map.put(login, "user_id", user_id)
        changeset = Login.changeset(%Login{}, login)
        Repo.insert!(changeset)
      end
    end)
  end
end
