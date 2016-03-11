defmodule ExMoney.Category do
  use ExMoney.Web, :model

  alias ExMoney.Category

  schema "categories" do
    field :name, :string
    field :humanized_name, :string
    field :css_color, :string

    timestamps

    has_many :transactions, ExMoney.Transaction
    belongs_to :parent, ExMoney.Category
  end

  @required_fields ~w(name)
  @optional_fields ~w(parent_id humanized_name)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> Ecto.Changeset.put_change(:css_color, generate_color)
    |> put_humanized_name
  end

  def list do
    from c in Category, order_by: c.name, preload: [:parent]
  end

  def by_name(name) do
    from c in Category, where: c.name == ^name, limit: 1
  end

  def parents do
    from c in Category,
      where: is_nil(c.parent_id),
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
      select: c.id
  end

  def select_list do
    from c in Category,
      select: {c.humanized_name, c.id},
      order_by: c.humanized_name
  end

  def generate_color() do
    h = :random.uniform()
    s = 0.5
    v = 0.95

    h_i = round(h * 6)
    f = h * 6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f) * s)

    {r, g, b} = cond do
      h_i == 0 -> {v, t, p}
      h_i == 1 -> {q, v, p}
      h_i == 2 -> {p, v, t}
      h_i == 3 -> {p, q, v}
      h_i == 4 -> {t, p, v}
      h_i == 5 -> {v, p, q}
      true -> {v, t, p}
    end

    r_int = round(r * 256)
    g_int = round(g * 256)
    b_int = round(b * 256)

    "rgb(#{r_int}, #{g_int}, #{b_int})"
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
