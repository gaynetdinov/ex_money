defmodule ExMoney.Web.Plugs.SetLogin do
  import Plug.Conn

  alias ExMoney.{Login, Repo}

  def init(_opts) do
  end

  def call(conn, _) do
    login = Login.by_user_and_saltedge_login(
      conn.assigns[:user].id,
      conn.params["data"]["login_id"]
    ) |> Repo.one

    assign(conn, :login, login)
  end
end
