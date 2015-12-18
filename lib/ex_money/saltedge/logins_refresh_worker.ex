defmodule ExMoney.Saltedge.LoginsRefreshWorker do
  use GenServer

  require Logger

  alias ExMoney.Repo
  alias ExMoney.Login
  alias ExMoney.Account

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :logins_refresh_worker)
  end

  def init(:ok) do
    logins = Repo.all(Login)

    case logins do
      [] -> :ignore
      logins ->
        Enum.each(logins, fn(login) ->
          Process.send_after(self(), {:refresh, login}, 1000)
        end)

        {:ok, {}}
    end
  end

  def handle_info({:refresh, login}, state) do
    last_refreshed_at = last_refreshed_at(login.last_refreshed_at)

    case Timex.Date.diff(last_refreshed_at, Timex.Date.now, :secs) do
      secs when secs >= 3600 ->
        refresh_login(login)
      secs when secs < 3600 ->
        next_run = 3600 - secs

        Process.send_after(self(), {:refresh, login}, next_run * 1000)
    end

    {:noreply, state}
  end

  defp refresh_login(login) do
    body = """
      { "data": { "fetch_type": "recent" }}
    """

    result = ExMoney.Saltedge.Client.request(:put, "logins/#{login.saltedge_login_id}/refresh", body)
    |> Poison.decode!
    Logger.info("Refreshed login #{login.saltedge_login_id} with result => #{inspect(result)}")

    case result["data"]["refreshed"] do
      true ->
        login = Login.update_changeset(
          login,
          %{last_refreshed_at: :erlang.universaltime()}
        ) |> Repo.update!

        sync_transactions(login, login.stage)
      false ->
        Process.send_after(self(), {:refresh, login}, 5000)
    end
  end

  # Saltedge is still fetching date from bank, let's try in 5 secs.
  defp sync_transactions(login, stage) when stage != "finish" do
    Process.send_after(self(), {:refresh, login}, 5000)
  end

  # Yey, stage is finished, let's sync transactions then.
  defp sync_transactions(login, _stage) do
    accounts = Account.by_saltedge_login_id([login.saltedge_login_id])
    |> Repo.all

    Enum.each(accounts, fn(account) ->
      Process.send_after(:transactions_worker, {:fetch, account.saltedge_account_id}, 1000)
    end)
  end

  # Use now - 61 minutes to trigger syncing when last_refreshed_at is nil
  defp last_refreshed_at(nil) do
    Timex.Date.subtract(Timex.Date.now, Timex.Time.to_timestamp(61, :mins))
  end

  defp last_refreshed_at(last_refreshed_at) do
    Ecto.DateTime.to_erl(last_refreshed_at) |> Timex.Date.from
  end
end
