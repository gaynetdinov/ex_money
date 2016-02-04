defmodule ExMoney.Router do
  use ExMoney.Web, :router

  pipeline :browser_session do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :browser do
    plug :accepts, ["html"]
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
  end

  scope "/", ExMoney do
    pipe_through [:browser, :browser_session]

    get "/", DashboardController, :overview

    get "/login", SessionController, :new, as: :login
    post "/login", SessionController, :create, as: :login
    delete "/logout", SessionController, :delete, as: :logout
    get "/logout", SessionController, :delete, as: :logout

    scope "/dashboard" do
      get "/", DashboardController, :overview
      get "/overview", DashboardController, :overview
    end

    scope "/settings" do
      get "/logins", SettingsController, :logins
      resources "/accounts", AccountController
    end

    resources "/users", UserController
    resources "/transactions", TransactionController
  end

  scope "/m", as: :mobile do
    pipe_through [:browser, :browser_session]
    get "/", ExMoney.Mobile.DashboardController, :overview
    get "/dashboard", ExMoney.Mobile.DashboardController, :overview
    get "/overview", ExMoney.Mobile.DashboardController, :overview
    get "/login", ExMoney.Mobile.SessionController, :new, as: :login
    post "/login", ExMoney.Mobile.SessionController, :create, as: :login
    get "/expenses", ExMoney.Mobile.TransactionController, :expenses
    get "/income", ExMoney.Mobile.TransactionController, :income
    get "/transaction/new", ExMoney.Mobile.TransactionController, :new
    post "/transaction/create", ExMoney.Mobile.TransactionController, :create
    resources "/accounts", ExMoney.Mobile.AccountController, only: [:show]
  end


  scope "/saltedge", as: :saltedge do
    pipe_through [:browser, :browser_session]

    scope "/logins" do
      get "/new", ExMoney.Saltedge.LoginController, :new
      get "/sync", ExMoney.Saltedge.LoginController, :sync
    end

    scope "/accounts" do
      get "/sync", ExMoney.Saltedge.AccountController, :sync
    end

  end

  scope "/callbacks", as: :callbacks do
    pipe_through [:saltedge_api, :browser_session]

    post "/success", CallbacksController, :success, as: :success
    post "/failure", CallbacksController, :failure, as: :failure
    post "/notify", CallbacksController, :notify, as: :notify
    post "/interactive", CallbacksController, :interactive, as: :interactive
  end
end
