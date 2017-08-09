defmodule ExMoney.Category do
  use ExMoney.Web, :model

  alias ExMoney.Category

  schema "categories" do
    field :name, :string
    field :humanized_name, :string
    field :css_color, :string
    field :hidden, :boolean

    timestamps()

    has_many :transactions, ExMoney.Transaction
    belongs_to :parent, ExMoney.Category
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name parent_id humanized_name)a)
    |> validate_required(~w(name)a)
    |> Ecto.Changeset.put_change(:css_color, generate_color())
    |> put_humanized_name
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name humanized_name parent_id hidden css_color)a)
  end

  def visible do
    from c in Category, where: c.hidden != true
  end

  def list_with_hidden do
    from c in Category,
      order_by: c.name, preload: [:parent]
  end

  def list do
    from c in Category,
      where: c.hidden != true,
      order_by: c.name, preload: [:parent]
  end

  def by_id_with_parent(id) do
    from c in Category,
      where: c.hidden != true,
      where: c.id == ^id, preload: [:parent]
  end

  def by_name(name) do
    from c in Category,
      where: c.hidden != true,
      where: c.name == ^name, limit: 1
  end

  def by_name_with_hidden(name) do
    from c in Category,
      where: c.name == ^name, limit: 1
  end

  def parents_with_hidden do
    from c in Category,
      where: is_nil(c.parent_id),
      order_by: c.name,
      select: {c.humanized_name, c.id}
  end

  def parents_with_children do
    from c in Category,
      where: c.hidden != true,
      where: not is_nil(c.parent_id),
      group_by: c.parent_id,
      select: {c.parent_id, fragment("array_agg(id)")}
  end

  def parents do
    from c in Category,
      where: is_nil(c.parent_id),
      where: c.hidden != true,
      order_by: c.name,
      select: {c.humanized_name, c.id}
  end

  def by_ids(ids) do
    from c in Category,
      where: c.id in ^(ids)
  end

  def sub_categories_by_id(id) do
    from c in Category,
      where: c.parent_id == ^id,
      where: c.hidden != true,
      select: c.id
  end

  def sub_categories do
    from c in Category,
      where: not is_nil(c.parent_id),
      where: c.hidden != true,
      select: {c.humanized_name, c.id}
  end

  def select_list do
    from c in Category,
      where: c.hidden != true,
      select: {c.humanized_name, c.id},
      order_by: c.humanized_name
  end

  def generate_color do
    red = div((:rand.uniform(256) + 255), 2)
    green = div((:rand.uniform(256) + 255), 2)
    blue = div((:rand.uniform(256) + 255), 2)

    "rgb(#{red}, #{green}, #{blue})"
  end

  defp put_humanized_name(changeset) do
    case Ecto.Changeset.fetch_change(changeset, :name) do
      {:ok, name} ->
        humanized_name = String.replace(name, "_", " ") |> String.capitalize
        Ecto.Changeset.put_change(changeset, :humanized_name, humanized_name)
      :error -> changeset
    end
  end
end
