defmodule ExMoney.Saltedge.TransactionsWorker do
  use GenServer

  alias ExMoney.Repo
  alias ExMoney.Transaction

  @interval 20 * 60 * 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :transactions_worker)
  end

  def init(:ok) do
    Process.send_after(self(), :timeout, @interval)

    {:ok, {}}
  end

  def handle_info(:timeout, state) do
    fetch_transactions()

    Process.send_after(self(), :timeout, @interval)

    {:noreply, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def fetch_transactions() do
    response = ExMoney.Saltedge.Client.request(:get, "transactions")
    transactions = response["data"]

    Enum.each(transactions, fn(transaction) ->
      transaction = Map.put(transaction, "saltedge_transaction_id", transaction["id"])
      transaction = Map.put(transaction, "saltedge_account_id", transaction["account_id"])
      transaction = Map.drop(transaction, ["id"])
      transaction = Map.drop(transaction, ["account_id"])

      existing_transaction = Transaction.
        by_saltedge_transaction_id(transaction["saltedge_transaction_id"])
        |> Repo.one

      if !existing_transaction do
        changeset = Transaction.changeset(%Transaction{}, transaction)
        Repo.insert!(changeset)
      end
    end)
  end
end
