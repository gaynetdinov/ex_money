defmodule ExMoney.Saltedge.TransactionsWorker do
  use GenServer

  require Logger

  alias ExMoney.Repo
  alias ExMoney.Transaction
  alias ExMoney.Account

  @interval 20 * 60 * 1000

  def start_link(_opts \\ []) do
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

  def handle_cast(:fetch, state) do
    fetch_transactions()

    {:noreply, state}
  end

  def fetch_transactions() do
    account_ids =
      Repo.all(Account)
      |> Enum.map(fn(acc) -> acc.saltedge_account_id end)

    _fetch_transactions(account_ids)
  end

  defp _fetch_transactions([]), do: Logger.info("There are no accounts.")

  defp _fetch_transactions(_account_ids) do
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
