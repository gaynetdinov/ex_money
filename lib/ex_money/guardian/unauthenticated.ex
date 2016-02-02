defmodule ExMoney.Guardian.Unauthenticated do
  def unauthenticated(conn, _params) do
    Phoenix.Controller.redirect(conn, to: "/login")
  end
end
