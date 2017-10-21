defmodule ExMoney.Web.Api.V2.CategoryController do
  use ExMoney.Web, :controller

  alias ExMoney.Categories

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.ApiUnauthenticated

  def index(conn, _params) do
    categories = Categories.all()

    render conn, :index, categories: categories
  end
end
