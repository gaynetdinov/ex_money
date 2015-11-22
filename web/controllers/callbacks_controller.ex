defmodule CallbacksController do
  use ExMoney.Web, :controller

  alias ExMoney.User
  alias ExMoney.Login
  alias ExMoney.Repo

  import Ecto.Query

  def success(conn, params) do
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]

    user = User.by_customer_id(customer_id) |> Repo.one

    if user do
      changeset = Ecto.Model.build(user, :logins)
      |> Login.success_callback_changeset(%{saltedge_login_id: login_id})
      if changeset.valid? do
        case Repo.insert(changeset) do
          {:ok, login} ->
            # create job to fetch all login info by login_id
            send_resp(conn, 200, "ok")
          {:error, changeset} ->
            # log error
            send_resp(conn, 200, "ok")
        end
      else
        # log error
        send_resp(conn, 200, "ok")
      end
    else
      # log fishy error
      send_resp(conn, 200, "ok")
    end
  end

  def failure(conn, params) do
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]

    user = User.by_customer_id(customer_id) |> Repo.one

    if user do
      changeset = Ecto.Model.build(user, :logins)
      |> Login.failure_callback_changeset(%{
        saltedge_login_id: login_id,
        last_fail_error_class: params["data"]["error_class"],
        last_fail_message: params["data"]["message"]
      })
      if changeset.valid? do
        case Repo.insert(changeset) do
          {:ok, login} ->
            # create job to fetch all login info by login_id
            send_resp(conn, 200, "ok")
          {:error, changeset} ->
            # log error
            send_resp(conn, 200, "ok")
        end
      else
        # log error
        send_resp(conn, 200, "ok")
      end
    else
      # log fishy error
      send_resp(conn, 200, "ok")
    end
  end

  def notify(conn, params) do
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]
    stage = params["data"]["stage"]

    user = User.by_customer_id(customer_id) |> Repo.one

    if user do
      login = Login
      |> where([l], l.user_id == ^user.id)
      |> where([l], l.saltedge_login_id == ^login_id)
      |> Repo.one

      changeset = Login.notify_callback_changeset(login, %{stage: stage})

      if changeset.valid? do
        case Repo.update(changeset) do
          {:ok, login} ->
            # create job to fetch all login info by login_id
            send_resp(conn, 200, "ok")
          {:error, changeset} ->
            # log error
            send_resp(conn, 200, "ok")
        end
      else
        # log error
        send_resp(conn, 200, "ok")
      end
    else
      # log fishy error
      send_resp(conn, 200, "ok")
    end
  end
end
