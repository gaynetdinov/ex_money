defmodule ExMoney.Money do
  def to_millicents(value) when is_binary(value) do
    {:ok, value} = Decimal.parse(value)
    to_millicents(value)
  end

  def to_millicents(value) do
    {millicents, _} =
      value
      |> Decimal.mult(Decimal.new(1000))
      |> to_string
      |> Integer.parse

    millicents
  end
end
