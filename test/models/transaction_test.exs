defmodule ExMoney.TransactionTest do
  use ExMoney.ModelCase

  alias ExMoney.Transaction

  @valid_attrs %{amount: "120.5", category: "some content", category_id: 42, currency_code: "some content", description: "some content", duplicated: true, made_on: "2010-04-17 14:00:00", mode: "some content", saltedge_account_id: 42, saltedge_transaction_id: 42, status: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Transaction.changeset(%Transaction{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Transaction.changeset(%Transaction{}, @invalid_attrs)
    refute changeset.valid?
  end
end
