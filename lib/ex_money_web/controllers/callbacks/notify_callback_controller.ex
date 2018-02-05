defmodule ExMoney.Web.Callbacks.NotifyCallbackController do
  use ExMoney.Web, :controller

  require Logger

  alias ExMoney.{Repo, Login, Web.Plugs}

  plug Plugs.SetUser
  plug Plugs.SetLogin

  def notify(conn, params) do
    stage = params["data"]["stage"]
    login = conn.assigns[:login]

    if login do
      changeset = Login.notify_callback_changeset(login, %{stage: stage})

      with {:ok, updated_login} <- Repo.update(changeset) do
        sync_data(updated_login, stage)
      end
    end

    put_resp_content_type(conn, "application/json")
    |> send_resp(200, Poison.encode!(%{}))
  end

  defp sync_data(_login, stage) when stage != "finish", do: :ok

  defp sync_data(login, _stage) do
    GenServer.cast(:sync_buffer, {:schedule, :sync, login})

    update_login_last_refreshed_at(login)
  end

  defp update_login_last_refreshed_at(login) do
    Login.update_changeset(
      login,
      %{last_refreshed_at: NaiveDateTime.utc_now()}
    ) |> Repo.update!
    Logger.info("last_refreshed_at for login #{login.saltedge_login_id} has been updated")
  end
end
