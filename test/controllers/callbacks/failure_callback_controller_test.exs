defmodule ExMoney.Web.Callbacks.FailureCallbackControllerTest do
  use ExMoney.Web.ConnCase
  import ExMoney.Factory

  alias ExMoney.{Repo, Login}

  test "successful callback", %{conn: conn} do
    user = insert(:user)
    login_id = 123

    body = [
      data: [
        customer_id: user.saltedge_customer_id,
        login_id: login_id,
        error_class: "SomethingInvalid",
        error_message: "Something went wrong"
      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn, "/callbacks/failure", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.last_fail_error_class == "SomethingInvalid"
    assert login.last_fail_message == "Something went wrong"
    assert login.saltedge_login_id == login_id
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

    conn = post conn, "/callbacks/failure", body
    logins = Repo.all(Login)

    assert conn.status == 400
    assert logins == []
  end
end
