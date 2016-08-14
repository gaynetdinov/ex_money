defmodule ExMoney.CallbacksControllerTest.Success do
  use ExMoney.ConnCase
  import ExMoney.Factory

  alias ExMoney.{Repo, Login}

  setup_all do
    ExMoney.Saltedge.Test.LoginLogger.start_link

    :ok
  end

  test "successful callback", %{conn: conn} do
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

  test "when updates login", %{conn: conn} do
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

defmodule ExMoney.CallbacksControllerTest.Failure do
  use ExMoney.ConnCase
  import ExMoney.Factory

  alias ExMoney.{Repo, Login}

  setup_all do
    ExMoney.Saltedge.Test.LoginLogger.start_link

    :ok
  end

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

defmodule ExMoney.CallbacksControllerTest.Notify do
  use ExMoney.ConnCase

  import ExMoney.Factory

  alias ExMoney.{Repo, Login}

  setup_all do
    ExMoney.Saltedge.Test.LoginLogger.start_link

    :ok
  end

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

defmodule ExMoney.CallbacksControllerTest.Interactive do
  use ExMoney.ConnCase
  import ExMoney.Factory

  alias ExMoney.{Repo, Login}

  setup_all do
    ExMoney.Saltedge.Test.LoginLogger.start_link

    :ok
  end

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
