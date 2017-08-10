defmodule ExMoney.Web.Settings.CategoryController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Category}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated
  plug :scrub_params, "category" when action in [:create, :update]

  def index(conn, _params) do
    categories = Category.list |> Repo.all

    render conn, :index,
      topbar: "settings",
      navigation: "categories",
      categories: categories
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
        |> redirect(to: settings_category_path(conn, :index))
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
    changeset = Category.changeset(category, category_params)

    case Repo.update(changeset) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Category updated successfully.")
        |> redirect(to: settings_category_path(conn, :index))
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
    |> redirect(to: settings_category_path(conn, :index))
  end

  def sync(conn, _params) do
    categories = with {:ok, response} <- ExMoney.Saltedge.Client.request(:get, "categories"),
                  do: response["data"]

    Repo.transaction(fn ->
      Enum.each(categories, fn({main_category, sub_categories}) ->
        category = create_or_update_category(main_category)

        Enum.each(sub_categories, fn(sub_category) ->
          create_or_update_category(sub_category, category.id)
        end)
      end)
    end)

    redirect(conn, to: settings_category_path(conn, :index))
  end

  defp create_or_update_category(name, parent_id \\ nil) do
    case Category.by_name(name) |> Repo.one do
      nil ->
        Category.changeset(%Category{}, %{name: name, parent_id: parent_id})
        |> Repo.insert!

      existing_category ->
        Category.changeset(existing_category, %{parent_id: parent_id})
        |> Repo.update!
    end
  end
end
