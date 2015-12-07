defmodule ExMoney.CallbacksControllerTest.Success do
  use ExMoney.ConnCase

  import ExMoney.Factory

  alias ExMoney.Repo
  alias ExMoney.Login

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(Repo)
    :ok
  end

  test "successful callback" do
    user = create(:user)
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

    conn = post conn(), "/callbacks/success", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.saltedge_login_id == login_id
    assert login.user_id == user.id
  end

  test "when user is not found by customer_id" do
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

    conn = post conn(), "/callbacks/success", body
    logins = Repo.all(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert logins == []
  end
end

defmodule ExMoney.CallbacksControllerTest.Failure do
  use ExMoney.ConnCase

  import ExMoney.Factory

  alias ExMoney.Repo
  alias ExMoney.Login

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(Repo)
    :ok
  end

  test "successful callback" do
    user = create(:user)
    login_id = 123

    body = [
      data: [
        customer_id: user.saltedge_customer_id,
        login_id: login_id,
        error_class: "SomethingInvalid",
        message: "Something went wrong"
      ],
      meta: [
        version: "2",
        time: "2015-12-04T09:54:09Z"
      ]
    ]

    conn = post conn(), "/callbacks/failure", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.last_fail_error_class == "SomethingInvalid"
    assert login.last_fail_message == "Something went wrong"
    assert login.saltedge_login_id == login_id
  end

  test "when user is not found by customer_id" do
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

    conn = post conn(), "/callbacks/failure", body
    logins = Repo.all(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert logins == []
  end
end

defmodule ExMoney.CallbacksControllerTest.Notify do
  use ExMoney.ConnCase

  import ExMoney.Factory

  alias ExMoney.Repo
  alias ExMoney.Login

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(Repo)
    :ok
  end

  test "successful callback" do
    login = create(:login)

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

    conn = post conn(), "/callbacks/notify", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.stage == "start"
  end

  test "when user is not found by customer_id" do
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

    conn = post conn(), "/callbacks/notify", body
    logins = Repo.all(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert logins == []
  end
end

defmodule ExMoney.CallbacksControllerTest.Interactive do
  use ExMoney.ConnCase

  import ExMoney.Factory

  alias ExMoney.Repo
  alias ExMoney.Login

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(Repo)
    :ok
  end

  test "successful callback" do
    login = create(:login)

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

    conn = post conn(), "/callbacks/interactive", body
    login = Repo.one(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert login.stage == "interactive"
    assert login.interactive_fields_names == ["image"]
    assert login.interactive_html == "<body>Interactive!</body>"
  end

  test "when user is not found by customer_id" do
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

    conn = post conn(), "/callbacks/interactive", body
    logins = Repo.all(Login)

    assert conn.status == 200
    assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    assert logins == []
  end
end
