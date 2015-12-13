defmodule ExMoney.Saltedge.TransactionsWorker do
  use GenServer

  require Logger

  import Ecto.Query

  alias ExMoney.Repo
  alias ExMoney.Transaction

  @interval 29 * 60 * 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: :transactions_worker)
  end

  def init(opts) do
    Process.send_after(self(), {:fetch, opts[:saltedge_account_id]}, @interval)

    {:ok, {}}
  end

  def handle_info({:fetch, saltedge_account_id}, state) do
    fetch_transactions(saltedge_account_id)

    Process.send_after(self(), {:fetch, saltedge_account_id}, @interval)

    {:noreply, state}
  end

  def handle_cast({:fetch, saltedge_account_id}, state) do
    fetch_transactions(saltedge_account_id)

    {:noreply, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def fetch_transactions(saltedge_account_id) do
    # FIXME: set last_transaction_id in cache during import
    last_transaction = Transaction
    |> where([tr], tr.saltedge_account_id == ^saltedge_account_id)
    |> order_by([tr], desc: tr.saltedge_transaction_id)
    |> limit([tr], 1)
    |> Repo.one

    case last_transaction do
      nil ->
        # import all, it's the very first run
        fetch_all(saltedge_account_id)
      transaction ->
        # import only starting +from_id=transaction_id+
        fetch_recent(saltedge_account_id, transaction.saltedge_transaction_id)
    end
  end

  defp fetch_recent(saltedge_account_id, last_transaction_id) do
    transactions = fetch_recent(saltedge_account_id, last_transaction_id, []) |> List.flatten

    store(transactions)
  end

  defp fetch_recent(saltedge_account_id, from_id, acc) do
    endpoint = "transactions?account_id=#{saltedge_account_id}&from_id=#{from_id}"

    response = ExMoney.Saltedge.Client.request(:get, endpoint)

    case {response["data"], response["meta"]["next_id"]} do
      {[], _} -> acc
      {_data, nil} -> acc
      {data, next_id} ->
        fetch_recent(
          saltedge_account_id,
          next_id,
          [data | acc]
        )
    end
  end

  defp fetch_all(saltedge_account_id) do
    to = current_date()
    from = substract_days(to, 30)
    transactions = fetch_all(saltedge_account_id, from, to, nil, []) |> List.flatten

    store(transactions)
  end

  defp fetch_all(saltedge_account_id, from, to, next_id, acc) do
    endpoint = "transactions?account_id=#{saltedge_account_id}&from_date=#{date_to_string(from)}&to_date=#{date_to_string(to)}"
    if next_id do
      endpoint = endpoint <> "&next_id=#{next_id}"
    end

    response = ExMoney.Saltedge.Client.request(:get, endpoint)

    case {response["data"], response["meta"]["next_id"]} do
      {[], _} -> acc

      {data, nil} ->
        fetch_all(
          saltedge_account_id,
          substract_days(from, 30),
          substract_days(from, 1),
          nil,
          [data | acc]
        )
      {data, next_id} ->
        fetch_all(
          saltedge_account_id,
          from,
          to,
          next_id,
          [data | acc]
        )
    end
  end

  defp store(transactions) do
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

  defp date_to_string(date) do
    Tuple.to_list(date) |> Enum.join("-")
  end

  defp substract_days(date, days) do
    :calendar.gregorian_days_to_date(
      :calendar.date_to_gregorian_days(date) - days
    )
  end

  defp current_date do
    {date, _time} = :calendar.local_time()

    date
  end
end
