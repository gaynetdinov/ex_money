defmodule ExMoney.CategoryController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Category}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated
  plug :scrub_params, "category" when action in [:create, :update]

  def index(conn, _params) do
    categories = Repo.all(Category.order_by_name)

    render(conn, :index,
      topbar: "settings",
      navigation: "categories",
      categories: categories
    )
  end

  def new(conn, _params) do
    categories = Repo.all(Category.parents)
    changeset = Category.changeset(%Category{})

    render(conn, :new,
      changeset: changeset,
      categories: categories,
      topbar: "settings",
      navigation: "categories"
    )
  end

  def create(conn, %{"category" => category_params}) do
    changeset = Category.changeset(%Category{}, category_params)

    case Repo.insert(changeset) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Category created successfully.")
        |> redirect(to: category_path(conn, :index))
      {:error, changeset} ->
        render(conn, :new, changeset: changeset, topbar: "settings", navigation: "categories")
    end
  end

  def show(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)
    render(conn, :show, category: category, topbar: "settings", navigation: "categories")
  end

  def edit(conn, %{"id" => id}) do
    categories = Repo.all(Category.parents)
    category = Repo.get!(Category, id)
    changeset = Category.changeset(category)
    render(conn, :edit,
      category: category,
      categories: categories,
      changeset: changeset,
      topbar: "settings",
      navigation: "categories"
    )
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    category = Repo.get!(Category, id)
    changeset = category.changeset(category, category_params)

    case Repo.update(changeset) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Category updated successfully.")
        |> redirect(to: category_path(conn, :show, category))
      {:error, changeset} ->
        render(conn, :edit,
          category: category,
          changeset: changeset,
          topbar: "settings",
          navigation: "categories"
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)

    Repo.delete!(category)

    conn
    |> put_flash(:info, "Category deleted successfully.")
    |> redirect(to: category_path(conn, :index))
  end
end
