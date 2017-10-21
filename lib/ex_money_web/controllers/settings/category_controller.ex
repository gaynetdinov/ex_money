defmodule ExMoney.Web.Settings.CategoryController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Categories}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated
  plug :scrub_params, "category" when action in [:create, :update]

  def index(conn, _params) do
    categories = Categories.list()

    render conn, :index,
      topbar: "settings",
      navigation: "categories",
      categories: categories
  end

  def new(conn, _params) do
    categories = Categories.parents()
    changeset = Categories.category_changeset()

    render conn, :new,
      changeset: changeset,
      categories: categories,
      topbar: "settings",
      navigation: "categories"
  end

  def create(conn, %{"category" => category_params}) do
    case Categories.create_category(category_params) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Category created successfully.")
        |> redirect(to: settings_category_path(conn, :index))
      {:error, changeset} ->
        render(conn, :new, changeset: changeset, topbar: "settings", navigation: "categories")
    end
  end

  def show(conn, %{"id" => id}) do
    category = Categories.get_category!(id)

    render(conn, :show, category: category, topbar: "settings", navigation: "categories")
  end

  def edit(conn, %{"id" => id}) do
    categories = Categories.parents()
    category = Categories.get_category!(id)
    changeset = Categories.category_changeset(category)

    render(
      conn, :edit,
      category: category,
      categories: categories,
      changeset: changeset,
      topbar: "settings",
      navigation: "categories"
    )
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    category = Categories.get_category!(id)

    case Categories.update_category(category, category_params) do
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
    Categories.delete_category!(id)

    conn
    |> put_flash(:info, "Category deleted successfully.")
    |> redirect(to: settings_category_path(conn, :index))
  end

  def sync(conn, _params) do
    categories = with {:ok, response} <- ExMoney.Saltedge.Client.request(:get, "categories"),
                  do: response["data"]

    Repo.transaction fn ->
      Enum.each categories, fn({main_category, sub_categories}) ->
        category = create_or_update_category(main_category)

        Enum.each sub_categories, fn(sub_category) ->
          create_or_update_category(sub_category, category.id)
        end
      end
    end

    redirect(conn, to: settings_category_path(conn, :index))
  end

  defp create_or_update_category(name, parent_id \\ nil) do
    case Categories.get_category_by(name: name) do
      nil ->
        Categories.create_category!(%{name: name, parent_id: parent_id})

      existing_category ->
        Categories.update_category!(existing_category, %{parent_id: parent_id})
    end
  end
end
