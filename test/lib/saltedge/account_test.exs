defmodule ExMoney.Saltedge.AccountTest do
  use ExMoney.ModelCase
  alias ExMoney.Account

  import ExMoney.Factory

  setup do
    bypass = Bypass.open

    {:ok, bypass: bypass}
  end

  describe "sync function" do
    setup %{bypass: bypass} do
      response = %{
        "data" => [
          %{
            "id" => 142,
            "name" => "Fake account 1",
            "nature" => "card",
            "balance" => 2007.2,
            "currency_code" => "EUR",
            "extra" => %{"client_name" => "Fake name"},
            "login_id" => 123,
            "created_at" => "2016-08-25T05:23:33Z",
            "updated_at" => "2016-08-25T05:23:33Z"
          }
        ]
      }

      new_config = Application.get_env(:ex_money, :saltedge)
      |> put_in([:base_url], "http://localhost:#{bypass.port}")
      Application.put_env(:ex_money, :saltedge, new_config)

      login = insert(:login, saltedge_login_id: 123)

      Bypass.expect bypass, fn conn ->
        assert "/accounts" == conn.request_path
        assert "login_id=123" == conn.query_string
        assert "GET" == conn.method
        Plug.Conn.resp(conn, 200, Poison.encode!(response))
      end

      {:ok, login: login}
    end

    test "create a new account", %{login: login} do
      ExMoney.Saltedge.Account.sync(login.user_id, login.saltedge_login_id)

      account = Repo.one(Account)

      assert account.saltedge_account_id == 142
      assert account.name == "Fake account 1"
      assert account.nature == "card"
      assert account.balance == Decimal.from_float(2007.2)
      assert account.currency_code == "EUR"
      assert account.currency_code == "EUR"
    end

    test "update an account", %{login: login} do
      account = insert(:account,
        login: login,
        balance: Decimal.new(1000),
        saltedge_account_id: 142
      )

      ExMoney.Saltedge.Account.sync(login.user_id, login.saltedge_login_id)

      account = Repo.get(Account, account.id)

      assert account.balance == Decimal.from_float(2007.2)
    end
  end
end
