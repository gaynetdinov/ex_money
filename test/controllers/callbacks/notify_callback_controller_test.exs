defmodule ExMoney.Web.Callbacks.NotifyCallbackControllerTest do
  use ExMoney.Web.ConnCase
  import ExMoney.Factory

  alias ExMoney.{Repo, Login}

  test "successful callback when customer_id is saltedge_customer_id", %{conn: conn} do
    login = insert(:login)

    body = [
      data: [
        customer_id: login.user.saltedge_customer_id,
        login_id: login.saltedge_login_id,
        stage: "start"
      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn, "/callbacks/notify", body

    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.stage == "start"
  end

  test "successful callback when customer_id is saltedge_id", %{conn: conn} do
    login = insert(:login)

    body = [
      data: [
        customer_id: login.user.saltedge_id,
        login_id: login.saltedge_login_id,
        stage: "start"
      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn, "/callbacks/notify", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.stage == "start"
  end

  test "when user is not found", %{conn: conn} do
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

    conn = post conn, "/callbacks/notify", body
    logins = Repo.all(Login)

    assert conn.status == 400
    assert logins == []
  end

  test "when a login is not found", %{conn: conn} do
    user = insert(:user)

    body = [
      data: [
        customer_id: user.saltedge_customer_id,
        login_id: 123
      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn, "/callbacks/notify", body
    logins = Repo.all(Login)

    assert conn.status == 200
    assert logins == []
  end
end
