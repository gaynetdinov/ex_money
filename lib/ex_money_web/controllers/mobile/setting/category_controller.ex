defmodule ExMoney.Web.Mobile.Setting.CategoryController do
  use ExMoney.Web, :controller

  alias ExMoney.{Category, Repo}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def index(conn, _params) do
    categories = Repo.all(Category.list_with_hidden)

    parent_categories = Enum.filter(categories, fn(c) -> is_nil(c.parent_id) end)

    sub_categories_map = Enum.reduce parent_categories, %{}, fn(c, acc) ->
      sub_categories = Enum.filter(categories, fn(sub_c) -> sub_c.parent_id == c.id end)
      Map.put(acc, c.id, sub_categories)
    end

    render conn, :index,
      parent_categories: parent_categories,
      sub_categories_map: sub_categories_map
  end

  def show(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)

    render conn, :show, category: category
  end

  def new(conn, _params) do
    parent_categories = Repo.all(Category.parents_with_hidden)
    changeset = Category.changeset(%Category{})

    render conn, :new,
      changeset: changeset,
      parent_categories: parent_categories
  end

  def create(conn, %{"category" => category_params}) do
    changeset = Category.changeset(%Category{}, category_params)

    case Repo.insert(changeset) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Category created successfully.")
        |> redirect(to: mobile_setting_category_path(conn, :index))
      {:error, changeset} ->
        render(conn, :new, changeset: changeset, topbar: "settings", navigation: "categories")
    end
  end

  def edit(conn, %{"id" => id}) do
    parent_categories = Category.parents_with_hidden |> Repo.all
    category = Repo.get(Category, id)
    changeset = Category.update_changeset(category)

    render conn, :edit,
      category: category,
      parent_categories: parent_categories,
      changeset: changeset
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    category = Repo.get!(Category, id)
    changeset = Category.update_changeset(category, category_params)

    case Repo.update(changeset) do
      {:ok, _category} ->
        send_resp(conn, 200, "")
      {:error, _changeset} ->
        send_resp(conn, 422, "Something went wrong, check server logs")
    end
  end
end
