defmodule ExMoney.Web.Callbacks.InteractiveCallbackControllerTest do
  use ExMoney.Web.ConnCase
  import ExMoney.Factory

  alias ExMoney.{Repo, Login}

  test "successful callback", %{conn: conn} do
    login = insert(:login)

    body = [
      data: [
        customer_id: login.user.saltedge_customer_id,
        login_id: login.saltedge_login_id,
        stage: "interactive",
        html: "<body>Interactive!</body>",
        interactive_fields_names: ["image"]
      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn, "/callbacks/interactive", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.stage == "interactive"
    assert login.interactive_fields_names == ["image"]
    assert login.interactive_html == "<body>Interactive!</body>"
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

    conn = post conn, "/callbacks/interactive", body
    logins = Repo.all(Login)

    assert conn.status == 400
    assert logins == []
  end
end
