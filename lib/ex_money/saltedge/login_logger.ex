defmodule ExMoney.Saltedge.LoginLogger do
  use GenServer
  require Logger

  alias ExMoney.{Repo, LoginLog, Login}

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :login_logger)
  end

  def handle_cast({:log, callback, event, saltedge_login_id, params}, state) do
    case Login.by_saltedge_login_id(saltedge_login_id) |> Repo.one do
      nil -> Logger.error("Could not create a login log entry, login with saltedge_login_id #{saltedge_login_id} not found")
      login ->
        changeset = LoginLog.changeset(%LoginLog{}, %{
          callback: callback,
          event: event,
          params: params,
          login_id: login.id
        })

        case Repo.insert(changeset) do
          {:ok, _} -> Logger.info("Login log entry has been created.")
          {:error, changeset} -> Logger.error("Could not create a login log entry, #{inspect(changeset.errors)}")
        end
    end

    {:noreply, state}
  end
end
