defmodule ExMoney.Saltedge.LoginController do
  use ExMoney.Web, :controller

  alias ExMoney.SessionController
  alias Guardian.Plug.EnsureAuthenticated
  alias ExMoney.User
  alias ExMoney.Repo

  plug EnsureAuthenticated, %{ on_failure: { SessionController, :new } }

  def new(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    body =
      """
        {
          "data": {
            "customer_id": "#{user.saltedge_customer_id}",
            "fetch_type": "recent"
          }
        }
      """
    response = ExMoney.Saltedge.Client.request(:post, "tokens/create", body)

    user_changeset = User.update_changeset(user, %{token: response["data"]["token"]})
    Repo.update!(user_changeset)

    connect_url = response["data"]["connect_url"]

    redirect conn, external: connect_url
  end

  def sync(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    ExMoney.Saltedge.Login.sync(user.id)

    redirect(conn, to: "/settings/logins")
  end
end
