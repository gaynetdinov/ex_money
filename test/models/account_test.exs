defmodule ExMoney.AccountTest do
  use ExMoney.ModelCase

  alias ExMoney.Account

  @valid_attrs %{balance: "120.5", currency_code: "some content", name: "some content", nature: "some content", saltedge_login_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Account.changeset(%Account{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Account.changeset(%Account{}, @invalid_attrs)
    refute changeset.valid?
  end
end
