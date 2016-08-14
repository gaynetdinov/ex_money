defmodule ExMoney.Saltedge.LoginRefreshWorker do
  use GenServer

  require Logger

  alias ExMoney.{Repo, Login}

  @interval 3_600_000

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :login_refresh_worker)
  end

  def init(:ok) do
    logins = Login.background_refresh |> Repo.all

    case logins do
      [] -> :ignore
      logins ->
        Enum.each(logins, fn(login) ->
          Process.send_after(self(), {:refresh, login.id}, 100)
        end)

        {:ok, %{}}
    end
  end

  def handle_info({:refresh, login_id}, state) do
    login = Repo.get(Login, login_id)
    last_refreshed_at = last_refreshed_at(login.last_refreshed_at)

    case Timex.Date.diff(last_refreshed_at, Timex.Date.now, :secs) do
      secs when secs >= 3600 ->
        refresh_login(login)

        Process.send_after(self(), {:refresh, login_id}, @interval)
      secs when secs < 3600 ->
        next_run = 3600 - secs

        Process.send_after(self(), {:refresh, login_id}, next_run * 1000)
    end

    {:noreply, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  defp refresh_login(login) do
    fetch_type = fetch_type(login.fetch_all_tried)

    body = """
      { "data": { "fetch_type": "#{fetch_type}" }}
    """

    result = ExMoney.Saltedge.Client.request(:put, "logins/#{login.saltedge_login_id}/refresh", body)
    case result do
      {:error, reason} ->
        GenServer.cast(:login_logger, {:log, "", "refresh_request_failed", login.saltedge_login_id, reason})
        Logger.error("Could not refresh login #{login.saltedge_login_id} with fetch_type #{fetch_type}")
      {:ok, response} ->
        GenServer.cast(:login_logger, {:log, "", "refresh_request_ok", login.saltedge_login_id, response})
        Logger.info("Login #{login.saltedge_login_id} has been successfully refreshed with fetch_type #{fetch_type}!")
    end

    set_fetch_all_tried(login, fetch_type)
  end

  # Use now - 61 minutes to trigger syncing when last_refreshed_at is nil
  defp last_refreshed_at(nil) do
    Timex.Date.subtract(Timex.Date.now, Timex.Time.to_timestamp(61, :mins))
  end

  defp last_refreshed_at(last_refreshed_at) do
    Ecto.DateTime.to_erl(last_refreshed_at) |> Timex.Date.from
  end

  defp fetch_type(fetch_all_tried) when fetch_all_tried == true, do: "recent"
  defp fetch_type(fetch_all_tried) when fetch_all_tried == false, do: "full"

  defp set_fetch_all_tried(login, "recent"), do: login
  defp set_fetch_all_tried(login, "full") do
    Login.update_changeset(login, %{fetch_all_tried: true})
    |> Repo.update!
  end
end
