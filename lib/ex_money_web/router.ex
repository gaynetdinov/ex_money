defmodule ExMoney.Web.Router do
  use ExMoney.Web, :router

  pipeline :browser_session do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :saltedge_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader, realm: "Token"
    plug Guardian.Plug.LoadResource
  end

  scope "/", ExMoney.Web do
    pipe_through [:browser, :browser_session]

    get "/", DashboardController, :overview

    get "/login", SessionController, :new, as: :login
    get "/setup/new", SetupController, :new
    post "/setup/complete", SetupController, :complete
    post "/login", SessionController, :create, as: :login
    delete "/logout", SessionController, :delete, as: :logout
    get "/logout", SessionController, :delete, as: :logout

    scope "/dashboard" do
      get "/", DashboardController, :overview
      get "/overview", DashboardController, :overview
    end

    scope "/settings", Settings, as: :settings do
      get "/user", UserController, :edit
      put "/user", UserController, :update
      resources "/accounts", AccountController
      get "/categories/sync", CategoryController, :sync
      resources "/categories", CategoryController
      resources "/rules", RuleController
      resources "/logins", LoginController, only: [:index, :delete, :show]
    end

    resources "/transactions", TransactionController
  end

  scope "/m", ExMoney.Web.Mobile, as: :mobile do
    pipe_through [:browser, :browser_session]

    get "/", StartController, :index
    get "/dashboard", DashboardController, :overview
    get "/overview", DashboardController, :overview
    get "/login", SessionController, :new, as: :login
    post "/login", SessionController, :create, as: :login
    get "/accounts/:id/refresh", AccountController, :refresh
    get "/accounts/:id/expenses", AccountController, :expenses
    get "/accounts/:id/income", AccountController, :income
    resources "/accounts", AccountController, only: [:show]
    resources "/transactions", TransactionController
    post "/transactions/create_from_fav", TransactionController, :create_from_fav

    resources "/favourite_transactions", FavouriteTransactionController do
      put "/fav", FavouriteTransactionController, :fav, as: :fav, param: "id"
    end

    get "/budget", BudgetController, :index
    get "/budget/expenses", BudgetController, :expenses
    get "/budget/income", BudgetController, :income
    resources "/budget_history", BudgetHistoryController, only: [:index, :show]

    scope "/settings", as: :setting do
      get "/", SettingController, :index
      resources "/budget", Setting.BudgetController, only: [:new, :show, :edit, :update, :create], singleton: true do
        post "/apply", Setting.BudgetController, :apply
      end
      resources "/budget_items", Setting.BudgetItemController, only: [:delete]

      resources "/categories", Setting.CategoryController, only: [:index, :edit, :update]
    end
  end

  scope "/saltedge", ExMoney.Web.Saltedge, as: :saltedge do
    pipe_through [:browser, :browser_session]

    scope "/logins" do
      get "/new", LoginController, :new
      get "/:id/sync", LoginController, :sync
    end

    scope "/accounts" do
      get "/sync", AccountController, :sync
    end
  end

  scope "/callbacks", ExMoney.Web.Callbacks, as: :callbacks do
    pipe_through [:saltedge_api, :browser_session]

    post "/success", SuccessCallbackController, :success, as: :success
    post "/failure", FailureCallbackController, :failure, as: :failure
    post "/notify", NotifyCallbackController, :notify, as: :notify
    post "/interactive", InteractiveCallbackController, :interactive, as: :interactive
    post "/destroy", DestroyCallbackController, :destroy, as: :destroy
  end

  scope "/api/v2", ExMoney.Web.Api.V2, as: :api do
    pipe_through [:api_auth]

    post "/login", SessionController, :login
    resources "/accounts", AccountController, only: [:index]
    resources "/categories", CategoryController, only: [:index]
    get "/transactions/recent", TransactionController, :recent, as: :recent
  end

  scope "/api/v1", ExMoney.Web.Api.V1, as: :api do
    pipe_through [:api]
    get "/session/relogin", SessionController, :relogin
  end
end
