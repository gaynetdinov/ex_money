defmodule ExMoney.TransactionInfoTest do
  use ExMoney.ModelCase

  alias ExMoney.TransactionInfo

  @valid_attrs %{account_number: "some content", additional: "some content", check_number: "some content", customer_category_code: "some content", customer_category_name: "some content", information: "some content", mcc: 42, original_amount: "120.5", original_category: "some content", original_currency_code: "some content", original_subcategory: "some content", payee: "some content", posting_date: "2010-04-17", posting_time: "2010-04-17 14:00:00", record_number: "some content", tags: [], time: "2010-04-17 14:00:00", type: "some content", unit_price: "120.5", units: "120.5"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = TransactionInfo.changeset(%TransactionInfo{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = TransactionInfo.changeset(%TransactionInfo{}, @invalid_attrs)
    refute changeset.valid?
  end
end
