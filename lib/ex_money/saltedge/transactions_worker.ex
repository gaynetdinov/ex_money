defmodule ExMoney.Saltedge.TransactionsWorker do
  use GenServer

  require Logger

  import Ecto.Query

  alias ExMoney.Repo
  alias ExMoney.Transaction
  alias ExMoney.TransactionInfo
  alias ExMoney.Category

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :transactions_worker)
  end

  def handle_cast({:fetch_all, saltedge_account_id}, state) do
    to = current_date()
    from = substract_days(to, 30)
    fetch_all(saltedge_account_id, from, to, [])

    {:noreply, state}
  end

  def handle_cast({:fetch_recent, saltedge_account_id}, state) do
    last_transaction = find_last_transaction(saltedge_account_id)

    fetch_recent(saltedge_account_id, last_transaction.saltedge_transaction_id)

    {:noreply, state}
  end

  def handle_info({:fetch_recent, saltedge_account_id}, state) do
    last_transaction = find_last_transaction(saltedge_account_id)

    fetch_recent(saltedge_account_id, last_transaction.saltedge_transaction_id)

    {:noreply, state}
  end

  def handle_call({:fetch_recent, saltedge_account_id}, _from, state) do
    last_transaction = find_last_transaction(saltedge_account_id)

    {:ok, transactions_count} = fetch_recent(saltedge_account_id, last_transaction)

    {:reply, {:ok, transactions_count}, state}
  end

  def handle_call({:fetch_custom, saltedge_account_id, from, to}, _from, state) do
    transactions = fetch_custom(saltedge_account_id, from, to, nil, [])

    store(transactions)

    {:reply, {:ok, Enum.count(transactions)}, state}
  end

  defp fetch_recent(saltedge_account_id, nil) do
    Logger.warn("There are no transactions in DB for account with id #{saltedge_account_id}")

    {:ok, 0}
  end

  defp fetch_recent(saltedge_account_id, last_transaction) do
    transactions = fetch_recent(saltedge_account_id, last_transaction.saltedge_transaction_id, [])
    |> List.flatten

    store(transactions)

    {:ok, Enum.count(transactions)}
  end

  defp fetch_recent(saltedge_account_id, from_id, acc) do
    endpoint = "transactions?account_id=#{saltedge_account_id}&from_id=#{from_id}"

    response = ExMoney.Saltedge.Client.request(:get, endpoint)

    case {response["data"], response["meta"]["next_id"]} do
      {[], _} -> acc
      {data, nil} -> [data | acc]
      {data, next_id} ->
        fetch_recent(
          saltedge_account_id,
          next_id,
          [data | acc]
        )
    end
  end

  defp fetch_all(saltedge_account_id, from, to, acc) do
    transactions_chunk = fetch_custom(saltedge_account_id, from, to, nil, [])

    transactions = case transactions_chunk do
      [] -> List.flatten(acc)
      transactions_chunk ->
        to = substract_days(from, 30)
        from = substract_days(from, 1)
        fetch_all(saltedge_account_id, from, to, [transactions_chunk | acc])
    end

    store(transactions)
  end

  defp fetch_custom(saltedge_account_id, from, to, next_id, acc) do
    endpoint = "transactions?account_id=#{saltedge_account_id}&from_date=#{from}&to_date=#{to}"
    if next_id do
      endpoint = endpoint <> "&next_id=#{next_id}"
    end

    response = ExMoney.Saltedge.Client.request(:get, endpoint)

    case {response["data"], response["meta"]["next_id"]} do
      {[], _} -> List.flatten(acc)
      {data, nil} -> List.flatten([data | acc])
      {data, next_id} ->
        fetch_custom(
          saltedge_account_id,
          from,
          to,
          next_id,
          [data | acc]
        )
    end
  end

  defp store(transactions) do
    Enum.each(transactions, fn(se_tran) ->
      se_tran = Map.put(se_tran, "saltedge_transaction_id", se_tran["id"])
      se_tran = Map.put(se_tran, "saltedge_account_id", se_tran["account_id"])
      se_tran = Map.drop(se_tran, ["id"])
      se_tran = Map.drop(se_tran, ["account_id"])

      existing_transaction = Transaction.
        by_saltedge_transaction_id(se_tran["saltedge_transaction_id"])
        |> Repo.one

      unless existing_transaction do
        se_tran = set_category_id(se_tran)

        changeset = Transaction.changeset(%Transaction{}, se_tran)
        Repo.transaction fn ->
          transaction = Repo.insert!(changeset)

          extra = Map.put(se_tran["extra"], "transaction_id", transaction.id)
          transaction_info = TransactionInfo.changeset(%TransactionInfo{}, extra)

          Repo.insert!(transaction_info)
        end
      end
    end)
  end

  defp set_category_id(transaction) do
    category = find_or_create_category(transaction["category"])

    Map.put(transaction, "category_id", category.id)
  end

  defp find_or_create_category(name) do
    case Category.by_name(name) |> Repo.one do
      nil ->
        changeset = Category.changeset(%Category{}, %{name: name})
        Repo.insert!(changeset)

      existing_category -> existing_category
    end
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

  defp find_last_transaction(saltedge_account_id) do
    # FIXME: set last_transaction_id in cache during import
    Transaction.oldest(saltedge_account_id)
    |> Repo.one
  end
end
