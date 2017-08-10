defmodule ExMoney.Web.Saltedge.LoginController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, User, Login}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated

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

    {:ok, response} = ExMoney.Saltedge.Client.request(:post, "tokens/create", body)

    user_changeset = User.update_changeset(user, %{token: response["data"]["token"]})
    Repo.update!(user_changeset)

    connect_url = response["data"]["connect_url"]

    redirect conn, external: connect_url
  end

  def sync(conn, %{"id" => login_id}) do
    user = Guardian.Plug.current_resource(conn)
    login = Repo.get!(Login, login_id)

    GenServer.call(:sync_worker, {:sync, user.id, login.saltedge_login_id})

    redirect(conn, to: "/settings/logins")
  end
end
