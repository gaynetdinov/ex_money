defmodule ExMoney.TransactionController do
  use ExMoney.Web, :controller

  alias ExMoney.{Transaction, Repo, Paginator, Account, Category}
  import Ecto.Query

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated
  plug :scrub_params, "transaction" when action in [:create, :update]

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    paginator = Transaction.by_user_id(user.id)
    |> order_by(desc: :made_on)
    |> preload([:transaction_info, :account, :saltedge_account, :category])
    |> Paginator.paginate(params)

    render conn, :index,
      topbar: "dashboard",
      navigation: "transactions",
      transactions: paginator.entries,
      page_number: paginator.page_number,
      total_pages: paginator.total_pages
  end

  def new(conn, _params) do
    changeset = Transaction.changeset(%Transaction{})
    accounts = Account.only_custom |> Repo.all
    categories = Category.select_list |> Repo.all

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
    changeset = Transaction.changeset_custom(%Transaction{}, transaction_params)

    case Repo.insert(changeset) do
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
    transaction = Repo.get!(Transaction, id)

    render conn, :show,
      transaction: transaction,
      topbar: "dashboard",
      navigation: "transactions"
  end

  def edit(conn, %{"id" => id}) do
    transaction = Repo.get!(Transaction, id)
    changeset = Transaction.changeset(transaction)

    render conn, :edit,
      transaction: transaction,
      changeset: changeset,
      topbar: "dashboard",
      navigation: "transactions"
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = Repo.get!(Transaction, id)
    changeset = Transaction.changeset(transaction, transaction_params)

    case Repo.update(changeset) do
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
    Repo.get!(Transaction, id) |> Repo.delete!

    redirect(conn, to: transaction_path(conn, :index))
  end
end
