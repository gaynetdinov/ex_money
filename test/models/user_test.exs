defmodule ExMoney.UserTest do
  use ExMoney.ModelCase

  alias ExMoney.User

  @valid_attrs %{email: "some content", encrypted_password: "some content", name: "some content", saltedge_customer_id: "some content", saltedge_token: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
