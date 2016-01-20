defmodule ExMoney.Guardian.Mobile.Unauthenticated do
  def unauthenticated(conn, _params) do
    Phoenix.Controller.redirect(conn, to: "/m/login")
    |> Plug.Conn.halt
  end
end
