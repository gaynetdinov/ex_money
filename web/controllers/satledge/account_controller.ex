defmodule ExMoney.Saltedge.AccountController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Login}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated

  def sync(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    login_ids = Login.by_user_id(user.id)
    |> Repo.all
    |> Enum.map(fn(login) -> login.saltedge_login_id end)

    ExMoney.Saltedge.Account.sync(login_ids)

    redirect(conn, to: "/settings/accounts")
  end
end
