defmodule CallbacksController do
  use ExMoney.Web, :controller

  require Logger

  alias ExMoney.{Repo, User, Login}

  plug :set_user
  plug :set_login when action in [:success, :notify, :interactive, :destroy, :failure]

  def success(conn, params) do
    Logger.info("Success: #{inspect(params)}")

    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]

    user = conn.assigns[:user]

    # FIXME WHAT A MESS
    case conn.assigns[:login] do
      nil ->
        changeset = Ecto.Model.build(user, :logins)
        |> Login.success_callback_changeset(%{saltedge_login_id: login_id, user_id: user.id})

        if changeset.valid? do
          case Repo.insert(changeset) do
            {:ok, login} ->
              update_login_last_refreshed_at(login)
              GenServer.cast(:sync_buffer, {:schedule, :sync, login})
              schedule_login_refresh_worker(login)

              put_resp_content_type(conn, "application/json")
              |> send_resp(200, "")
            {:error, changeset} ->
              Logger.info("Could not create Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
              put_resp_content_type(conn, "application/json")
              |> send_resp(200, "")
          end
        else
          Logger.info("Could not create Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "")
        end
      login ->
        changeset = Login.update_changeset(login, params["data"])
        {result, _} = Repo.update(changeset)
        Logger.info("Login was updated with result => #{inspect(result)}")
        update_login_last_refreshed_at(login)
        GenServer.cast(:sync_buffer, {:schedule, :sync, login})

        put_resp_content_type(conn, "application/json")
        |> send_resp(200, "")
    end
  end

  def notify(conn, params) do
    Logger.info("Notify: #{inspect(params)}")
    customer_id = params["data"]["customer_id"]
    stage = params["data"]["stage"]

    login = conn.assigns[:login]

    changeset = Login.notify_callback_changeset(login, %{stage: stage})

    if changeset.valid? do
      case Repo.update(changeset) do
        {:ok, login} ->
          sync_data(login, stage)

          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "ok")
        {:error, changeset} ->
          Logger.info("Could not update Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "ok")
      end
    else
      Logger.info("Could not update Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
      put_resp_content_type(conn, "application/json")
      |> send_resp(200, "ok")
    end
  end

  def interactive(conn, params) do
    Logger.info("Interactive: #{inspect(params)}")
    customer_id = params["data"]["customer_id"]
    stage = params["data"]["stage"]
    html = params["data"]["html"]
    interactive_fields_names = params["data"]["interactive_fields_names"]

    login = conn.assigns[:login]

    changeset = Login.interactive_callback_changeset(login, %{
      stage: stage,
      interactive_fields_names: interactive_fields_names,
      interactive_html: html
    })

    if changeset.valid? do
      case Repo.update(changeset) do
        {:ok, _login} ->
          pid = get_channel_pid(conn.assigns[:user].id)
          Process.send_after(pid, {:interactive, html, interactive_fields_names}, 10)

          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "ok")
        {:error, changeset} ->
          Logger.info("Interactive: Could not update Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "ok")
      end
    else
      Logger.info("Interactive: Could not update Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
      put_resp_content_type(conn, "application/json")
      |> send_resp(200, "ok")
    end
  end

  def failure(conn, params) do
    Logger.info("Failure: #{inspect(params)}")
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]
    user = conn.assigns[:user]

    case conn.assigns[:login] do
      nil ->
        changeset = Ecto.Model.build(user, :logins)
        |> Login.failure_callback_changeset(%{
          saltedge_login_id: login_id,
          last_fail_error_class: params["data"]["error_class"],
          last_fail_message: params["data"]["message"]
        })
        if changeset.valid? do
          case Repo.insert(changeset) do
            {:ok, _login} ->
              put_resp_content_type(conn, "application/json")
              |> send_resp(200, "ok")
            {:error, changeset} ->
              Logger.info("Could not create Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
              put_resp_content_type(conn, "application/json")
              |> send_resp(200, "ok")
          end
        else
          Logger.info("Could not create Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "ok")
        end
      login ->
        params = %{
          last_fail_error_class: params["data"]["error_class"],
          last_fail_message: params["data"]["message"]
        }

        Login.failure_callback_changeset(login, params)
        |> Repo.update
        Logger.info("Login has been updated with failure reason.")

        otp_done(user.id)

        put_resp_content_type(conn, "application/json")
        |> send_resp(200, "ok")
    end
  end

  def destroy(conn, params) do
    Logger.info("Destroy: #{inspect(params)}")
    login = conn.assigns[:login]

    Repo.transaction(fn -> Repo.delete!(login) end)

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
        case User.by_customer_id(customer_id) |> Repo.one do
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

  defp otp_done(user_id) do
    user_id = "user:#{user_id}"
    key = "ongoing_interactive_#{user_id}"
    :ets.update_element(:ex_money_cache, key, {2, false})
  end
end
