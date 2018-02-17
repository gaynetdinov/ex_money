defmodule ExMoney.Web.TransactionController do
  use ExMoney.Web, :controller

  alias ExMoney.{Transactions.Transaction, Repo, Paginator, Account, Category}
  alias ExMoney.Transactions
  import Ecto.Query

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated
  plug :scrub_params, "transaction" when action in [:create, :update]

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    paginator = Transactions.by_user_id(user.id)
    |> order_by(desc: :made_on)
    |> preload([:account, :saltedge_account, :category])
    |> Paginator.paginate(params)

    render conn, :index,
      topbar: "dashboard",
      navigation: "transactions",
      transactions: paginator.entries,
      page_number: paginator.page_number,
      total_pages: paginator.total_pages
  end

  def new(conn, _params) do
    changeset = Transactions.changeset_custom()
    accounts = Account.only_custom |> Repo.all

    categories_dict = Repo.all(Category)

    categories = Enum.reduce(categories_dict, %{}, fn(category, acc) ->
      if is_nil(category.parent_id) do
        sub_categories = Enum.filter(categories_dict, fn(c) -> c.parent_id == category.id end)
        |> Enum.map(fn(sub_category) -> {sub_category.humanized_name, sub_category.id} end)
        Map.put(acc, {category.humanized_name, category.id}, sub_categories)
      else
        acc
      end
    end)

    render conn, :new,
      changeset: changeset,
      topbar: "dashboard",
      navigation: "transactions",
      accounts: accounts,
      categories: categories
  end

  def create(conn, %{"transaction" => transaction_params}) do
    user = Guardian.Plug.current_resource(conn)
    transaction_params = Map.put(transaction_params, "user_id", user.id)

    case Transactions.create_custom_transaction(transaction_params) do
      {:ok, _transaction} ->
        redirect(conn, to: transaction_path(conn, :index))
      {:error, changeset} ->
        render conn, :new,
          changeset: changeset,
          topbar: "dashboard",
          navigation: "transactions"
    end
  end

  def show(conn, %{"id" => id}) do
    transaction = Transactions.get_transaction(id)

    render conn, :show,
      transaction: transaction,
      topbar: "dashboard",
      navigation: "transactions"
  end

  def edit(conn, %{"id" => id}) do
    transaction = Repo.get!(Transaction, id)
    changeset = Transactions.changeset(transaction)

    render conn, :edit,
      transaction: transaction,
      changeset: changeset,
      topbar: "dashboard",
      navigation: "transactions"
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = Transactions.get_transaction!(id)

    case Transactions.update_transaction(transaction, transaction_params) do
      {:ok, transaction} ->
        redirect(conn, to: transaction_path(conn, :show, transaction))
      {:error, changeset} ->
        render conn, :edit,
          transaction: transaction,
          changeset: changeset,
          topbar: "dashboard",
          navigation: "transactions"
    end
  end

  def delete(conn, %{"id" => id}) do
    Transactions.delete_transaction!(id)

    redirect(conn, to: transaction_path(conn, :index))
  end
end
