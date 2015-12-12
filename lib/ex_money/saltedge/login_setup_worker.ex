defmodule ExMoney.Saltedge.LoginSetupWorker do
  use GenServer
  import Ecto.Query
  require Logger

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :login_setup_worker)
  end

  def handle_info({:setup, user_id, login_id}, state) do
    login = fetch_login(user_id, login_id, 5)

    ExMoney.Saltedge.Account.sync([login.saltedge_login_id])

    account_ids = ExMoney.Account
    |> where([a], a.saltedge_login_id == ^login.saltedge_login_id)
    |> ExMoney.Repo.all
    |> Enum.map(fn(account) -> GenServer.cast(:transactions_worker, {:fetch, account.saltedge_account_id}) end)

    {:stop, :normal, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  defp fetch_login(user_id, login_id, attempts) do
    ExMoney.Saltedge.Login.sync(user_id, login_id)

    login = ExMoney.Login
    |> where([l], l.saltedge_login_id == ^login_id)
    |> limit([l], 1)
    |> ExMoney.Repo.one

    case login.status do
      _ when attempts == 0 ->
        Logger.error("LoginSetupWorker has been stopped because login #{login.id} is still not active")
        GenServer.call(:login_setup_worker, :stop)
      "active" -> login
      "inactive" ->
        :timer.sleep(3000)
        fetch_login(user_id, login_id, attempts - 1)
      "disabled" ->
        Logger.error("Login #{login_id} is disabled.")
        GenServer.call(:login_setup_worker, :stop)
    end
  end
end
