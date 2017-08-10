defmodule ExMoney.Web.Api.V2.CategoryView do
  use ExMoney.Web, :view

  alias ExMoney.Web.Api.V2.CategoryView

  def render("index.json", %{categories: categories}) do
    render_many(categories, CategoryView, "category.json")
  end

  def render("category.json", %{category: category}) do
    %{
       id: category.id,
       name: category.name,
       human_name: category.humanized_name,
       parent_id: category.parent_id
     }
  end
end
