defmodule ExMoney.Guardian.ApiUnauthenticated do
  def unauthenticated(conn, _params) do
    conn
    |> Plug.Conn.put_status(401)
    |> Phoenix.Controller.json(%{errors: ["Authentication required"]})
    |> Plug.Conn.halt()
  end
end
