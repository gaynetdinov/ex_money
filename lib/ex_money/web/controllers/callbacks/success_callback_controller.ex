defmodule ExMoney.Web.Callbacks.SuccessCallbackController do
  use ExMoney.Web, :controller

  @login_logger Application.get_env(:ex_money, :login_logger_worker)

  require Logger

  alias ExMoney.{Repo, Login, Web.Plugs}

  plug Plugs.SetUser
  plug Plugs.SetLogin

  def success(conn, params) do
    case conn.assigns[:login] do
      nil -> create_login(params["data"]["login_id"], conn)
      login -> update_login(login, conn)
    end

    put_resp_content_type(conn, "application/json")
    |> send_resp(200, Poison.encode!(%{}))
  end

  defp create_login(saltedge_login_id, conn) do
    user = conn.assigns[:user]
    changeset = Ecto.build_assoc(user, :logins)
    |> Login.success_callback_changeset(%{saltedge_login_id: saltedge_login_id, user_id: user.id})

    case Repo.insert(changeset) do
      {:ok, login} ->
        update_login_last_refreshed_at(login)
        GenServer.cast(:sync_buffer, {:schedule, :sync, login})
        schedule_login_refresh_worker(login)
        @login_logger.log_event("success", "login_created", saltedge_login_id, conn.params)

      {:error, changeset} ->
        @login_logger.log_event("success", "login_create_failed", saltedge_login_id, Enum.into(changeset.errors, %{}))
    end
  end

  defp update_login(login, conn) do
    changeset = Login.update_changeset(login, conn.params["data"])

    case Repo.update(changeset) do
      {:ok, _} ->
        @login_logger.log_event("success", "login_updated", login.saltedge_login_id, conn.params)
      {:error, changeset} ->
        @login_logger.log_event("success", "login_updated", login.saltedge_login_id, Enum.into(changeset.errors, %{}))
    end

    update_login_last_refreshed_at(login)
    GenServer.cast(:sync_buffer, {:schedule, :sync, login})
  end

  defp schedule_login_refresh_worker(login) do
    if login.interactive == false and login.automatic_fetch == true do
      Process.send_after(:login_refresh_worker, {:refresh, login.id}, 600 * 1000)
    end
  end

  defp update_login_last_refreshed_at(login) do
    Login.update_changeset(
      login,
      %{last_refreshed_at: NaiveDateTime.utc_now()}
    ) |> Repo.update!
    Logger.info("last_refreshed_at for login #{login.saltedge_login_id} has been updated")
  end
end
