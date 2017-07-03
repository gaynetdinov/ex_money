defmodule ExMoney.Callbacks.NotifyCallbackController do
  use ExMoney.Web, :controller

  @login_logger Application.get_env(:ex_money, :login_logger_worker)

  require Logger

  alias ExMoney.{Repo, Login, Plugs}

  plug Plugs.SetUser
  plug Plugs.SetLogin

  def notify(conn, params) do
    stage = params["data"]["stage"]
    login = conn.assigns[:login]

    if login do
      @login_logger.log_event("notify", "callback_received", login.saltedge_login_id, params)
      changeset = Login.notify_callback_changeset(login, %{stage: stage})

      case Repo.update(changeset) do
        {:ok, updated_login} ->
          sync_data(updated_login, stage)
          @login_logger.log_event("notify", "login_updated", login.saltedge_login_id, params)

        {:error, changeset} ->
          @login_logger.log_event("notify", "login_update_failed", login.saltedge_login_id, Enum.into(changeset.errors, %{}))
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
