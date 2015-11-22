defmodule ExMoney.LoginTest do
  use ExMoney.ModelCase

  alias ExMoney.Login

  @valid_attrs %{automatic_fetch: true, country_code: "some content", finished: true, finished_recent: true, interactive: true, interactive_fields_names: [], interactive_html: "some content", last_fail_at: "2010-04-17 14:00:00", last_fail_error_class: "some content", last_fail_message: "some content", last_request_at: "2010-04-17 14:00:00", last_success_at: "2010-04-17 14:00:00", partial: true, provider_name: "some content", provider_score: "some content", secret: "some content", stage: "some content", status: "some content", store_credentials: true}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Login.changeset(%Login{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Login.changeset(%Login{}, @invalid_attrs)
    refute changeset.valid?
  end
end
