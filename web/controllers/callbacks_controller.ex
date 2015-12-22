defmodule CallbacksController do
  use ExMoney.Web, :controller

  require Logger

  alias ExMoney.User
  alias ExMoney.Login
  alias ExMoney.Repo

  import Ecto.Query

  plug :set_user_by_customer_id

  def success(conn, params) do
    Logger.info("CallbackController#success: #{inspect(params)}")

    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]

    user = conn.assigns[:user]
    login = Login.by_user_and_saltedge_login(user.id, login_id) |> Repo.one

    # FIXME WHAT A MESS
    case login do
      nil ->
        changeset = Ecto.Model.build(user, :logins)
        |> Login.success_callback_changeset(%{saltedge_login_id: login_id, user_id: user.id})

        if changeset.valid? do
          case Repo.insert(changeset) do
            {:ok, _login} ->
              put_resp_content_type(conn, "application/json")
              |> send_resp(200, "")
            {:error, changeset} ->
              Logger.info("Success: Could not create Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
              put_resp_content_type(conn, "application/json")
              |> send_resp(200, "")
          end
        else
          # log error
          Logger.info("Success: Could not create Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "")
        end
      login ->
        changeset = Login.update_changeset(login, params["data"])
        {result, _} = Repo.update(changeset)
        Logger.info("Success: Login was updated with result => #{inspect(result)}")
        put_resp_content_type(conn, "application/json")
        |> send_resp(200, "")
    end
  end

  def failure(conn, params) do
    Logger.info("CallbackController#failure: #{inspect(params)}")
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]
    user = conn.assigns[:user]

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
          # log error
          Logger.infi("Failure: Could not create Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "ok")
      end
    else
      Logger.info("Failure: Could not create Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
      put_resp_content_type(conn, "application/json")
      |> send_resp(200, "ok")
    end
  end

  def notify(conn, params) do
    Logger.info("CallbackController#notify: #{inspect(params)}")
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]
    stage = params["data"]["stage"]
    user = conn.assigns[:user]

    login = Login
    |> where([l], l.user_id == ^user.id)
    |> where([l], l.saltedge_login_id == ^login_id)
    |> Repo.one

    changeset = Login.notify_callback_changeset(login, %{stage: stage})

    if changeset.valid? do
      case Repo.update(changeset) do
        {:ok, login} ->
          sync_data(user.id, login, stage)

          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "ok")
        {:error, changeset} ->
          Logger.info("Notify: Could not update Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
          put_resp_content_type(conn, "application/json")
          |> send_resp(200, "ok")
      end
    else
      Logger.info("Failure: Could not update Login for customer_id => #{inspect(customer_id)}, errors => #{inspect(changeset.errors)}")
      put_resp_content_type(conn, "application/json")
      |> send_resp(200, "ok")
    end
  end

  def interactive(conn, params) do
    Logger.info("CallbackController#interactive: #{inspect(params)}")
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]
    user = conn.assigns[:user]
    stage = params["data"]["stage"]
    html = params["data"]["html"]
    interactive_fields_names = params["data"]["interactive_fields_names"]

    login = Login
    |> where([l], l.user_id == ^user.id)
    |> where([l], l.saltedge_login_id == ^login_id)
    |> Repo.one

    changeset = Login.interactive_callback_changeset(login, %{
      stage: stage,
      interactive_fields_names: interactive_fields_names,
      interactive_html: html
    })

    if changeset.valid? do
      case Repo.update(changeset) do
        {:ok, _login} ->
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

  defp sync_data(_user_id, _login, stage) when stage != "finish", do: :ok

  defp sync_data(user_id, login, _stage) do
    GenServer.cast(:sync_worker, {:sync, user_id, login.saltedge_login_id})

    Login.update_changeset(
      login,
      %{last_refreshed_at: :erlang.universaltime()}
    ) |> Repo.update!
  end

  defp set_user_by_customer_id(conn, _opts) do
    case conn.params["data"]["customer_id"] do
      nil -> send_resp(conn, 400, "customer_id is missing") |> halt
      customer_id ->
        case User.by_customer_id(customer_id) |> Repo.one do
          nil ->
            Logger.info("Success: Could not create Login for customer_id => #{inspect(customer_id)}, User not found")
            # TODO: send as json?
            send_resp(conn, 400, "customer_id is not valid") |> halt
          user -> assign(conn, :user, user)
        end
    end
  end
end
