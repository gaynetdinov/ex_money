defmodule ExMoney.Web.ErrorHelper do
  def translate_error({message, values}) do
    Enum.reduce values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end

  def translate_error(message), do: message
end
