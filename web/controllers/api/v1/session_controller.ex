defmodule ExMoney.Api.V1.SessionController do
  use ExMoney.Web, :controller

  def relogin(conn, params) do
    case Guardian.Plug.current_resource(conn) do
      nil -> send_resp(conn, 401, "Unauthenticated")
      user ->
        conn = Guardian.Plug.sign_in(conn, user)
        send_resp(conn, 200, Guardian.Plug.current_token(conn))
    end
  end
end
