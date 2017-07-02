defmodule ExMoney.Web.Api.V2.CategoryController do
  use ExMoney.Web, :controller

  alias ExMoney.Category

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.ApiUnauthenticated

  def index(conn, _params) do
    categories = Repo.all(Category)

    render conn, :index, categories: categories
  end
end
