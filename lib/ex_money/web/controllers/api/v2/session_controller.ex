defmodule ExMoney.Web.Api.V2.SessionController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, User}

  plug :fetch_user

  def login(conn, params) do
    user = conn.private[:user]

    changeset = User.login_changeset(user, %{"password" => params["password"]})
    if changeset.valid? do
      new_conn = Guardian.Plug.api_sign_in(conn, user)
      jwt = Guardian.Plug.current_token(new_conn)
      {:ok, claims} = Guardian.Plug.claims(new_conn)
      exp = Map.get(claims, "exp")

      new_conn
      |> put_resp_header("authorization", "Token #{jwt}")
      |> put_resp_header("x-expires", to_string(exp))
      |> render("login.json", user: user, jwt: jwt, exp: exp)
    else
      send_error(conn)
    end
  end

  defp fetch_user(conn, _) do
    user = User.by_email(conn.params["email"] || "") |> Repo.one

    if user do
      put_private(conn, :user, user)
    else
      send_error(conn)
    end
  end

  defp send_error(conn) do
    conn
    |> put_status(401)
    |> halt
    |> render("error.json", message: "Email or password is incorrect")
  end
end
