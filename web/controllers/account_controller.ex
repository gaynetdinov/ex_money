defmodule ExMoney.AccountController do
  use ExMoney.Web, :controller
  use Guardian.Phoenix.Controller

  alias ExMoney.{Repo, Login, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated
  plug :scrub_params, "account" when action in [:create, :update]

  def index(conn, _params, user, _claims) do
    accounts = Account.by_user_id(user.id) |> Repo.all

    render(conn, "index.html", accounts: accounts, navigation: "accounts", topbar: "settings")
  end

  def new(conn, _params, _user, _claims) do
    changeset = Account.changeset(%Account{})
    render(conn, "new.html", changeset: changeset, topbar: "settings", navigation: "accounts")
  end

  def create(conn, %{"account" => account_params}, user, _claims) do
    account_params = Map.put(account_params, "user_id", user.id)
    changeset = Account.changeset_for_custom_account(%Account{}, account_params)

    case Repo.insert(changeset) do
      {:ok, _account} ->
        conn
        |> put_flash(:info, "Account created successfully.")
        |> redirect(to: account_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, topbar: "settings", navigation: "accounts")
    end
  end
end
