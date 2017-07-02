defmodule ExMoney.Web.Settings.CategoryView do
  use ExMoney.Web, :view

  def parent_category(nil), do: ""
  def parent_category(parent), do: parent.humanized_name
end
