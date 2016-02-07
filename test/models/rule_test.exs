defmodule ExMoney.RuleTest do
  use ExMoney.ModelCase

  alias ExMoney.Rule

  @valid_attrs %{account_id: 42, pattern: "some content", target_id: 42, type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Rule.changeset(%Rule{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Rule.changeset(%Rule{}, @invalid_attrs)
    refute changeset.valid?
  end
end
