defmodule ExMoney.IdleWorker do
  use GenServer

  @interval 25 * 60 * 1000 # 25 min

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :idle_worker)
  end

  def init(:ok) do
    Process.send_after(self(), :keep_alive, 1000)

    {:ok, %{}}
  end

  def handle_info(:keep_alive, state) do
    HTTPoison.request(:get, "https://#{System.get_env("HOME_URL")}", "", [], [recv_timeout: 30000])

    Process.send_after(self(), :keep_alive, @interval)

    {:noreply, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
end
