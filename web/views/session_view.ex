defmodule ExMoney.SessionView do
  use ExMoney.Web, :view

  def render("new.json", assigns) do
    Poison.encode!(assigns.users)
  end
end
