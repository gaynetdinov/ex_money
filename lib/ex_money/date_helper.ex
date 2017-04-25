defmodule ExMoney.DateHelper do
  def today do
    {today, _} = :calendar.local_time()
    today
  end

  def parse_date(month) when month == "" or is_nil(month) do
    Timex.Date.local
  end

  def parse_date(month) do
    {:ok, date} = Timex.DateFormat.parse(month, "{YYYY}-{0M}")
    date
  end

  def first_day_of_month(date) do
    Timex.Date.from({{date.year, date.month, 0}, {0, 0, 0}})
    |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
    |> elem(1)
  end

  def last_day_of_month(date) do
    days_in_month = Timex.Date.days_in_month(date)

    Timex.Date.from({{date.year, date.month, days_in_month}, {23, 59, 59}})
    |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
    |> elem(1)
  end

  def current_month(date) do
    {:ok, current_month} = Timex.DateFormat.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.DateFormat.format(date, "%b %Y", :strftime)

    %{date: current_month, label: label}
  end

  def next_month(date) do
    date = Timex.Date.shift(date, months: 1)

    {:ok, next_month} = Timex.DateFormat.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.DateFormat.format(date, "%b %Y", :strftime)

    %{date: next_month, label: label}
  end

  def previous_month(date) do
    date = Timex.Date.shift(date, months: -1)

    {:ok, previous_month} = Timex.DateFormat.format(date, "{YYYY}-{M}")
    {:ok, label} = Timex.DateFormat.format(date, "%b %Y", :strftime)

    %{date: previous_month, label: label}
  end
end
