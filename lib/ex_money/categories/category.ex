defmodule ExMoney.Categories.Category do
  use ExMoney.Web, :model

  alias ExMoney.Categories.Category

  schema "categories" do
    field :name, :string
    field :humanized_name, :string
    field :css_color, :string
    field :hidden, :boolean

    timestamps()

    has_many :transactions, ExMoney.Transaction
    belongs_to :parent, Category
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
