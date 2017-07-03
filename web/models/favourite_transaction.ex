defmodule ExMoney.FavouriteTransaction do
  use ExMoney.Web, :model

  alias ExMoney.FavouriteTransaction

  import Ecto.Query

  schema "favourite_transactions" do
    field :name, :string
    field :made_on, :date
    field :amount, :decimal
    field :currency_code, :string
    field :description, :string
    field :fav, :boolean, defaut: false

    belongs_to :category, ExMoney.Category
    belongs_to :user, ExMoney.User
    belongs_to :account, ExMoney.Account

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name account_id user_id category_id currency_code description amount fav)a)
    |> validate_required(~w(name account_id user_id)a)
  end

  def by_user_id(user_id) do
    from tr in FavouriteTransaction,
      where: tr.user_id == ^user_id
  end

  def fav_by_user_id(user_id) do
    from ftr in FavouriteTransaction,
      where: ftr.user_id == ^user_id,
      where: ftr.fav == true,
      limit: 1
  end

  def by_user_with_category(user_id) do
    from tr in FavouriteTransaction,
      where: tr.user_id == ^user_id,
      preload: [:category]
  end
end
