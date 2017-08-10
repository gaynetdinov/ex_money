defmodule ExMoney.Web.Callbacks.DestroyCallbackController do
  use ExMoney.Web, :controller

  @login_logger Application.get_env(:ex_money, :login_logger_worker)

  alias ExMoney.{Repo, Web.Plugs}

  plug Plugs.SetUser
  plug Plugs.SetLogin

  def destroy(conn, params) do
    login = conn.assigns[:login]

    @login_logger.log_event("destroy", "callback_received", login.saltedge_login_id, params)

    Repo.transaction(fn -> Repo.delete!(login) end)

    @login_logger.log_event("destroy", "login_destroyed", login.saltedge_login_id, params)

    put_resp_content_type(conn, "application/json")
    |> send_resp(200, Poison.encode!(%{}))
  end
end
