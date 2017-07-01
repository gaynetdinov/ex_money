defmodule ExMoney.DateHelperTest do
  use ExUnit.Case

  alias ExMoney.DateHelper

  test "parse_date when argument is nil" do
    result = DateHelper.parse_date(nil)

    assert result.year == Timex.local.year
    assert result.month == Timex.local.month
    assert result.day == Timex.local.day
  end

  test "parse_date when argument is empty" do
    result = DateHelper.parse_date("")

    assert result.year == Timex.local.year
    assert result.month == Timex.local.month
    assert result.day == Timex.local.day
  end

  test "first_day_of_month" do
    {:ok, date} = Date.new(2017, 10, 10)

    assert DateHelper.first_day_of_month(date) == "2017-10-01"
  end

  test "last_day_of_month" do
    date = Timex.to_date({2017, 12, 24})

    assert DateHelper.last_day_of_month(date) == "2017-12-31"
  end

  test "current_month" do
    date = Timex.to_date({2017, 12, 24})

    assert DateHelper.current_month(date) == %{date: "2017-12", label: "Dec 2017"}
  end

  test "next_month" do
    date = Timex.to_date({2017, 11, 24})

    assert DateHelper.next_month(date) == %{date: "2017-12", label: "Dec 2017"}
  end

  test "previous_month" do
    date = Timex.to_date({2017, 11, 24})

    assert DateHelper.previous_month(date) == %{date: "2017-10", label: "Oct 2017"}
  end
end
