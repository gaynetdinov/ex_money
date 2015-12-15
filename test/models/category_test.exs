defmodule ExMoney.CategoryTest do
  use ExMoney.ModelCase

  alias ExMoney.Category

  @valid_attrs %{name: "some content", parent_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Category.changeset(%Category{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Category.changeset(%Category{}, @invalid_attrs)
    refute changeset.valid?
  end
end
