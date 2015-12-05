defmodule ExMoney.TransactionControllerTest do
  use ExMoney.ConnCase

  alias ExMoney.Transaction
  @valid_attrs %{}
  @invalid_attrs %{}

  setup do
    conn = conn()
    {:ok, conn: conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, transaction_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing transactions"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, transaction_path(conn, :new)
    assert html_response(conn, 200) =~ "New transaction"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, transaction_path(conn, :create), transaction: @valid_attrs
    assert redirected_to(conn) == transaction_path(conn, :index)
    assert Repo.get_by(Transaction, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, transaction_path(conn, :create), transaction: @invalid_attrs
    assert html_response(conn, 200) =~ "New transaction"
  end

  test "shows chosen resource", %{conn: conn} do
    transaction = Repo.insert! %Transaction{}
    conn = get conn, transaction_path(conn, :show, transaction)
    assert html_response(conn, 200) =~ "Show transaction"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_raise Ecto.NoResultsError, fn ->
      get conn, transaction_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    transaction = Repo.insert! %Transaction{}
    conn = get conn, transaction_path(conn, :edit, transaction)
    assert html_response(conn, 200) =~ "Edit transaction"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    transaction = Repo.insert! %Transaction{}
    conn = put conn, transaction_path(conn, :update, transaction), transaction: @valid_attrs
    assert redirected_to(conn) == transaction_path(conn, :show, transaction)
    assert Repo.get_by(Transaction, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    transaction = Repo.insert! %Transaction{}
    conn = put conn, transaction_path(conn, :update, transaction), transaction: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit transaction"
  end

  test "deletes chosen resource", %{conn: conn} do
    transaction = Repo.insert! %Transaction{}
    conn = delete conn, transaction_path(conn, :delete, transaction)
    assert redirected_to(conn) == transaction_path(conn, :index)
    refute Repo.get(Transaction, transaction.id)
  end
end
