defmodule ExMoney.Categories do
  import Ecto.Query, warn: false

  alias ExMoney.Categories.Category
  alias ExMoney.Repo

  def category_changeset() do
    Category.changeset(%Category{})
  end

  def category_changeset(category) do
    Category.changeset(category)
  end

  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def create_category!(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert!()
  end

  def update_category(category, attrs \\ %{}) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def update_category!(category, attrs \\ %{}) do
    category
    |> Category.changeset(attrs)
    |> Repo.update!()
  end

  def all do
    Repo.all(Category)
  end

  def get_category(id), do: Repo.get(Category, id)
  def get_category!(id), do: Repo.get!(Category, id)

  def delete_category!(id) do
    category = get_category!(id)

    Repo.delete!(category)
  end

  def visible_categories() do
    query = from c in Category, where: c.hidden != true

    Repo.all(query)
  end

  def list_with_hidden do
    query = from c in Category, order_by: c.name, preload: [:parent]

    Repo.all(query)
  end

  def list do
    query =
      from c in Category,
        where: c.hidden != true,
        order_by: c.name, preload: [:parent]

    Repo.all(query)
  end

  def find_or_create_category_by_name(name) do
    case get_category_by(name: name) do
      nil ->
        create_category!(%{name: name})

      existing_category ->
        existing_category
    end
  end

  def get_category_by(params) do
    Repo.get_by(Category, params)
  end

  def get_category_by!(params) do
    Repo.get_by!(Category, params)
  end

  def parents_with_hidden do
    query =
      from c in Category,
        where: is_nil(c.parent_id),
        order_by: c.name,
        select: {c.humanized_name, c.id}

    Repo.all(query)
  end

  def parents do
    query =
      from c in Category,
        where: is_nil(c.parent_id),
        where: c.hidden != true,
        order_by: c.name,
        select: {c.humanized_name, c.id}

    Repo.all(query)
  end

  def get_categories_by_ids(ids) do
    query = from c in Category, where: c.id in ^(ids)

    Repo.all(query)
  end

  def get_sub_categories(parent_category_id) do
    query =
      from c in Category,
        where: c.parent_id == ^parent_category_id,
        where: c.hidden != true,
        select: c.id

    Repo.all(query)
  end
end
