# Copy-paste from http://blog.drewolson.org/pagination-with-phoenix-ecto/
defmodule ExMoney.Paginator do
  defstruct [:entries, :page_number, :page_size, :total_pages]

  import Ecto.Query

  alias ExMoney.Repo

  def paginate(query, params) do
    page_number = params
    |> Map.get("page", 1)
    |> to_int(1)
    |> avoid_negative_number

    page_size = params |> Map.get("page_size", 10) |> to_int(10)

    %ExMoney.Paginator{
      entries: entries(query, page_number, page_size),
      page_number: page_number,
      page_size: page_size,
      total_pages: total_pages(query, page_size)
    }
  end

  defp avoid_negative_number(number) when number <= 0, do: 1
  defp avoid_negative_number(value), do: value

  defp ceiling(float) do
    t = trunc(float)

    case float - t do
      neg when neg < 0 ->
        t
      pos when pos > 0 ->
        t + 1
      _ -> t
    end
  end

  defp entries(query, page_number, page_size) do
    offset = page_size * (page_number - 1)

    query
    |> limit([_], ^page_size)
    |> offset([_], ^offset)
    |> Repo.all
  end

  defp to_int(i, _fallback) when is_integer(i), do: i
  defp to_int(s, fallback) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> fallback
    end
  end

  defp total_pages(query, page_size) do
    count = query
    |> exclude(:order_by)
    |> exclude(:preload)
    |> exclude(:select)
    |> select([e], count(e.id))
    |> Repo.one

    ceiling(count / page_size)
  end
end
