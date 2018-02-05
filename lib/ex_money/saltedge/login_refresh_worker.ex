defmodule ExMoney.Saltedge.LoginRefreshWorker do
  use GenServer

  require Logger

  alias ExMoney.{Repo, Login}

  @interval 3_600_000
  @mix_env Mix.env

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :login_refresh_worker)
  end

  def init(:ok) do
    logins = Login.background_refresh() |> Repo.all

    if @mix_env == :dev or logins == [] do
      :ignore
    else
      Enum.each logins, fn(login) ->
        Process.send_after(self(), {:refresh, login.id}, 100)
      end

      {:ok, %{}}
    end
  end

  def handle_info({:refresh, login_id}, state) do
    login = Repo.get(Login, login_id)
    last_refreshed_at = last_refreshed_at(login.last_refreshed_at)

    case NaiveDateTime.diff(NaiveDateTime.utc_now(), last_refreshed_at, :second) do
      seconds when seconds >= 3600 ->
        refresh_login(login)

        Process.send_after(self(), {:refresh, login_id}, @interval)
      seconds when seconds < 3600 ->
        next_run = 3600 - seconds

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
      {:error, _reason} ->
        Logger.error("Could not refresh login #{login.saltedge_login_id} with fetch_type #{fetch_type}")
      {:ok, _response} ->
        Logger.info("Login #{login.saltedge_login_id} has been successfully refreshed with fetch_type #{fetch_type}!")
    end

    set_fetch_all_tried(login, fetch_type)
  end

  # Use now - 61 minutes to trigger syncing when last_refreshed_at is nil
  defp last_refreshed_at(nil) do
    NaiveDateTime.add(NaiveDateTime.utc_now(), -61 * 60)
  end

  defp last_refreshed_at(last_refreshed_at) do
    last_refreshed_at
  end

  defp fetch_type(fetch_all_tried) when fetch_all_tried == true, do: "recent"
  defp fetch_type(fetch_all_tried) when fetch_all_tried == false, do: "full"

  defp set_fetch_all_tried(login, "recent"), do: login
  defp set_fetch_all_tried(login, "full") do
    Login.update_changeset(login, %{fetch_all_tried: true})
    |> Repo.update!
  end
end
