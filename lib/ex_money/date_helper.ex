defmodule ExMoney.DateHelper do
  def today do
    {today, _} = :calendar.local_time()
    today
  end

  def parse_date(month) when month == "" or is_nil(month) do
    Timex.local
  end

  def parse_date(month) do
    {:ok, date} = Timex.parse(month, "{YYYY}-{M}")

    date
  end

  def first_day_of_month(date) do
    with {:ok, date} <- Date.new(date.year, date.month, 1) do
      Date.to_string(date)
    end
  end

  def last_day_of_month(date) do
    with {:ok, ex_date} <- Date.new(date.year, date.month, 1),
         days_in_month <- Date.days_in_month(ex_date),
         {:ok, date} <- Date.new(date.year, date.month, days_in_month) do

      Date.to_string(date)
    end
  end

  def current_month(date) do
    {:ok, current_month} = Timex.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.format(date, "%b %Y", :strftime)

    %{date: current_month, label: label}
  end

  def next_month(date) do
    date = Timex.shift(date, months: 1)

    {:ok, next_month} = Timex.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.format(date, "%b %Y", :strftime)

    %{date: next_month, label: label}
  end

  def previous_month(date) do
    date = Timex.shift(date, months: -1)

    {:ok, previous_month} = Timex.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.format(date, "%b %Y", :strftime)

    %{date: previous_month, label: label}
  end
end
