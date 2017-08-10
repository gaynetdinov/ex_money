defmodule ExMoney.Web.Mobile.FavouriteTransactionController do
  use ExMoney.Web, :controller
  alias ExMoney.{Repo, FavouriteTransaction, Category, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    fav_transactions = FavouriteTransaction.by_user_with_category(user.id) |> Repo.all

    render conn, :index,
      fav_transactions: fav_transactions
  end

  def new(conn, _params) do
    categories = categories_list()
    uncategorized = Map.keys(categories)
    |> Enum.find(fn({name, _id}) -> name == "Uncategorized" end)
    categories = Map.delete(categories, uncategorized)
    categories = [{uncategorized, []} | Map.to_list(categories)]

    accounts = Account.only_custom |> Repo.all

    changeset = FavouriteTransaction.changeset(%FavouriteTransaction{})

    render conn, :new,
      categories: categories,
      changeset: changeset,
      accounts: accounts
  end

  def fav(conn, %{"favourite_transaction_id" => id}) do
    transaction = Repo.get!(FavouriteTransaction, id)
    user = Guardian.Plug.current_resource(conn)

    changeset = FavouriteTransaction.changeset(transaction, %{fav: true})

    Repo.transaction(fn ->
      FavouriteTransaction.by_user_id(user.id)
      |> Repo.update_all(set: [fav: false])

      Repo.update!(changeset)
    end)

    send_resp(conn, 200, "")
  end

  def create(conn, %{"favourite_transaction" => transaction_params}) do
    user = Guardian.Plug.current_resource(conn)
    transaction_params = Map.put(transaction_params, "user_id", user.id)
    changeset = FavouriteTransaction.changeset(%FavouriteTransaction{}, transaction_params)

    case Repo.insert(changeset) do
      {:ok, _transaction} ->
        send_resp(conn, 200, "")
      {:error, _changeset} ->
        send_resp(conn, 422, "Something went wrong, check server logs")
    end
  end

  def delete(conn, %{"id" => id}) do
    transaction = Repo.get!(FavouriteTransaction, id)
    Repo.delete!(transaction)

    send_resp(conn, 200, "")
  end

  defp categories_list do
    categories_dict = Repo.all(Category)

    Enum.reduce(categories_dict, %{}, fn(category, acc) ->
      if is_nil(category.parent_id) do
        sub_categories = Enum.filter(categories_dict, fn(c) -> c.parent_id == category.id end)
        |> Enum.map(fn(sub_category) -> {sub_category.humanized_name, sub_category.id} end)
        Map.put(acc, {category.humanized_name, category.id}, sub_categories)
      else
        acc
      end
    end)
  end
end
