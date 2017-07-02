defmodule ExMoney.Web.Plugs.SetUser do
  import Plug.Conn
  require Logger
  alias ExMoney.{User, Repo}

  def init(_opts) do
  end

  def call(conn, _) do
    customer_id = conn.params["data"]["customer_id"]
    with user when not is_nil(user) <- User.by_saltedge_id(customer_id) |> Repo.one do
      assign(conn, :user, user)
    else
      nil ->
        Logger.info("Could not find User with customer_id '#{inspect(customer_id)}'")
        send_resp(conn, 400, Poison.encode!(%{error: "customer_id is missing or invalid"}))
        |> halt
    end
  end
end
