defmodule ExMoney.Web.Callbacks.SuccessCallbackControllerTest do
  use ExMoney.Web.ConnCase
  import ExMoney.Factory

  alias ExMoney.{Repo, Login}

  test "when login does not exist", %{conn: conn} do
    user = insert(:user)
    login_id = 123

    body = [
      data: [
        customer_id: user.saltedge_customer_id,
        login_id: login_id
      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn, "/callbacks/success", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.saltedge_login_id == login_id
    assert login.user_id == user.id
  end

  test "when login exists", %{conn: conn} do
    login = insert(:login)

    body = [
      data: [
        customer_id: login.user.saltedge_customer_id,
        login_id: login.saltedge_login_id,
        provider_score: "foo"

      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn, "/callbacks/success", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.provider_score == "foo"
  end

  test "when user is not found by customer_id", %{conn: conn} do
    body = [
      data: [
        customer_id: "foobar",
        login_id: 123
      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn, "/callbacks/success", body
    logins = Repo.all(Login)

    assert conn.status == 400
    assert logins == []
  end
end
