defmodule ExMoney.Guardian.Unauthenticated do
  def unauthenticated(conn, _params) do
    conn
    |> Plug.Conn.put_status(401)
    |> Phoenix.Controller.put_flash(:info, "Authentication required")
    |> Phoenix.Controller.redirect(to: "/login")
  end
end
