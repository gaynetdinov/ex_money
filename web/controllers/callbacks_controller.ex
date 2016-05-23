defmodule CallbacksController do
  use ExMoney.Web, :controller

  @login_logger_worker Application.get_env(:ex_money, :login_logger_worker)

  require Logger

  alias ExMoney.{Repo, User, Login}

  plug :set_user
  plug :set_login when action in [:success, :notify, :interactive, :destroy, :failure]

  def success(conn, params) do
    login_id = params["data"]["login_id"]
    user = conn.assigns[:user]

    # FIXME WHAT A MESS
    case conn.assigns[:login] do
      nil ->
        changeset = Ecto.Model.build(user, :logins)
        |> Login.success_callback_changeset(%{saltedge_login_id: login_id, user_id: user.id})

        case Repo.insert(changeset) do
          {:ok, login} ->
            update_login_last_refreshed_at(login)
            GenServer.cast(:sync_buffer, {:schedule, :sync, login})
            schedule_login_refresh_worker(login)
            add_login_event("success", "login_created", login_id, params)

            put_resp_content_type(conn, "application/json") |> send_resp(200, "")
          {:error, changeset} ->
            add_login_event("success", "login_create_failed", login_id, Enum.into(changeset.errors, %{}))
            put_resp_content_type(conn, "application/json") |> send_resp(200, "")
        end
      login ->
        changeset = Login.update_changeset(login, params["data"])

        case Repo.update(changeset) do
          {:ok, _} -> add_login_event("success", "login_updated", login_id, params)
          {:error, changeset} -> add_login_event("success", "login_updated", login_id, Enum.into(changeset.errors, %{}))
        end

        update_login_last_refreshed_at(login)
        GenServer.cast(:sync_buffer, {:schedule, :sync, login})

        put_resp_content_type(conn, "application/json") |> send_resp(200, "")
    end
  end

  def notify(conn, params) do
    stage = params["data"]["stage"]

    case conn.assigns[:login] do
      nil ->
        put_resp_content_type(conn, "application/json") |> send_resp(200, "")
      login ->
        add_login_event("notify", "callback_received", login.saltedge_login_id, params)
        changeset = Login.notify_callback_changeset(login, %{stage: stage})

        case Repo.update(changeset) do
          {:ok, updated_login} ->
            sync_data(updated_login, stage)
            add_login_event("notify", "login_updated", login.saltedge_login_id, params)

            put_resp_content_type(conn, "application/json") |> send_resp(200, "")
          {:error, changeset} ->
            add_login_event("notify", "login_update_failed", login.saltedge_login_id, Enum.into(changeset.errors, %{}))
            put_resp_content_type(conn, "application/json") |> send_resp(200, "")
        end
    end
  end

  def interactive(conn, params) do
    stage = params["data"]["stage"]
    html = params["data"]["html"]
    login_id = params["data"]["login_id"]
    interactive_fields_names = params["data"]["interactive_fields_names"]

    login = conn.assigns[:login]
    add_login_event("interactive", "callback_received", login_id, params)

    changeset = Login.interactive_callback_changeset(login, %{
      stage: stage,
      interactive_fields_names: interactive_fields_names,
      interactive_html: html
    })

    case Repo.update(changeset) do
      {:ok, _} ->
        pid = get_channel_pid(conn.assigns[:user].id)
        store_interactive_field_names(conn.assigns[:user].id, interactive_fields_names)
        Process.send_after(pid, {:interactive_callback_received, html, interactive_fields_names}, 10)

        add_login_event("interactive", "login_updated", login_id, params)

        put_resp_content_type(conn, "application/json") |> send_resp(200, "")
      {:error, changeset} ->
        add_login_event("interactive", "login_update_failed", login_id, Enum.into(changeset.errors, %{}))
        put_resp_content_type(conn, "application/json") |> send_resp(200, "")
    end
  end

  def failure(conn, params) do
    login_id = params["data"]["login_id"]
    user = conn.assigns[:user]

    case conn.assigns[:login] do
      nil ->
        changeset = Ecto.Model.build(user, :logins)
        |> Login.failure_callback_changeset(%{
          saltedge_login_id: login_id,
          last_fail_error_class: params["data"]["error_class"],
          last_fail_message: params["data"]["error_message"]
        })

        case Repo.insert(changeset) do
          {:ok, _login} ->
            add_login_event("failure", "login_created", login_id, params)
            put_resp_content_type(conn, "application/json") |> send_resp(200, "")
          {:error, changeset} ->
            add_login_event("failure", "login_create_failed", login_id, Enum.into(changeset.errors, %{}))
            put_resp_content_type(conn, "application/json") |> send_resp(200, "")
        end
      login ->
        params = %{
          last_fail_error_class: params["data"]["error_class"],
          last_fail_message: params["data"]["error_message"]
        }

        changeset = Login.failure_callback_changeset(login, params)
        case Repo.update(changeset) do
          {:ok, _} -> add_login_event("failure", "login_create_failed", login_id, params)
          {:error, changeset} -> add_login_event("failure", "login_create_failed", login_id, Enum.into(changeset.errors, %{}))
        end

        interactive_done(user.id)
        put_resp_content_type(conn, "application/json") |> send_resp(200, "")
    end
  end

  def destroy(conn, params) do
    login = conn.assigns[:login]

    add_login_event("destroy", "callback_received", login.saltedge_login_id, params)

    Repo.transaction(fn -> Repo.delete!(login) end)

    add_login_event("destroy", "login_destroyed", login.saltedge_login_id, params)

    put_resp_content_type(conn, "application/json") |> send_resp(200, "")
  end

  defp sync_data(_login, stage) when stage != "finish", do: :ok

  defp sync_data(login, _stage) do
    GenServer.cast(:sync_buffer, {:schedule, :sync, login})

    update_login_last_refreshed_at(login)
  end

  defp update_login_last_refreshed_at(login) do
    Login.update_changeset(
      login,
      %{last_refreshed_at: :erlang.universaltime()}
    ) |> Repo.update!
    Logger.info("last_refreshed_at for login #{login.saltedge_login_id} has been updated")
  end

  defp set_user(conn, _opts) do
    case conn.params["data"]["customer_id"] do
      nil -> send_resp(conn, 400, "customer_id is missing") |> halt
      customer_id ->
        case User.by_saltedge_id(customer_id) |> Repo.one do
          nil ->
            Logger.info("Could not find User with customer_id '#{inspect(customer_id)}'")
            # TODO: send as json?
            send_resp(conn, 400, "customer_id is not valid") |> halt
          user -> assign(conn, :user, user)
        end
    end
  end

  defp set_login(conn, _opts) do
    login = Login.by_user_and_saltedge_login(
      conn.assigns[:user].id,
      conn.params["data"]["login_id"]
    ) |> Repo.one

    assign(conn, :login, login)
  end

  defp schedule_login_refresh_worker(login) do
    if login.interactive == false and login.automatic_fetch == true do
      Process.send_after(:login_refresh_worker, {:refresh, login.id}, 600 * 1000)
    end
  end

  defp get_channel_pid(user_id) do
    user_id = "user:#{user_id}"
    key = "refresh_channel_pid_#{user_id}"

    case :ets.lookup(:ex_money_cache, key) do
      [] -> nil
      [{_key, value}] -> value
    end
  end

  defp interactive_done(user_id) do
    key = "ongoing_interactive_user:#{user_id}"
    :ets.update_element(:ex_money_cache, key, {2, false})
  end

  defp store_interactive_field_names(user_id, interactive_fields_names) do
    key = "ongoing_interactive_user:#{user_id}"

    case :ets.lookup(:ex_money_cache, key) do
      [] -> :ets.insert(:ex_money_cache, {key, interactive_fields_names})
      _ -> :ets.update_element(:ex_money_cache, key, {2, interactive_fields_names})
    end
  end

  defp add_login_event(callback, event, login_id, params) do
    GenServer.cast(@login_logger_worker.name, {:log, callback, event, login_id, params})
  end
end
