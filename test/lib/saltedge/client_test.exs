defmodule ExMoney.Saltedge.ClientTest do
  use ExUnit.Case, async: true

  import Plug.Conn

  setup do
    bypass = Bypass.open

    new_config =
      Application.get_env(:ex_money, :saltedge)
      |> put_in([:base_url], "http://localhost:#{bypass.port}")

    Application.put_env(:ex_money, :saltedge, new_config)

    {:ok, bypass: bypass}
  end

  test "a request with proper headers", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/endpoint" == conn.request_path
      assert "GET" == conn.method

      assert List.first(get_req_header(conn, "signature"))
      assert List.first(get_req_header(conn, "expires-at"))
      assert List.first(get_req_header(conn, "app-id"))
      assert List.first(get_req_header(conn, "secret"))

      assert ["application/json"] == get_req_header(conn, "accept")
      assert ["application/json"] == get_req_header(conn, "content-type")

      Plug.Conn.resp(conn, 200, ~s<{"data": [{"message": "response"}]}>)
    end

    {:ok, _} = ExMoney.Saltedge.Client.request(:get, "endpoint")
  end

  test "successful GET request", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/endpoint" == conn.request_path
      assert "GET" == conn.method

      Plug.Conn.resp(conn, 200, ~s<{"data": [{"message": "response"}]}>)
    end

    {:ok, response} = ExMoney.Saltedge.Client.request(:get, "endpoint")

    assert %{"data" => [%{"message" => "response"}]} == response
  end

  test "successful POST request", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      opts = [parsers: [:json], json_decoder: Poison]
      conn = Plug.Parsers.call(conn, Plug.Parsers.init(opts))

      assert "/endpoint" == conn.request_path
      assert "POST" == conn.method
      assert %{"foo" => "bar"} == conn.body_params
      Plug.Conn.resp(conn, 200, ~s<{}>)
    end

    {:ok, response} = ExMoney.Saltedge.Client.request(:post, "endpoint", ~s<{"foo": "bar"}>)

    assert %{} == response
  end

  test "unsuccessful request", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/endpoint" == conn.request_path
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 400, ~s<{"error": [{"message": "foobar"}]}>)
    end

    {:error, response} = ExMoney.Saltedge.Client.request(:get, "endpoint")

    assert %{"error" => [%{"message" => "foobar"}]} == response
  end
end
