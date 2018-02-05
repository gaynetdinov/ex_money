defmodule ExMoney.Web.Callbacks.DestroyCallbackController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Web.Plugs}

  plug Plugs.SetUser
  plug Plugs.SetLogin

  def destroy(conn, params) do
    login = conn.assigns[:login]

    Repo.transaction(fn -> Repo.delete!(login) end)

    put_resp_content_type(conn, "application/json")
    |> send_resp(200, Poison.encode!(%{}))
  end
end
