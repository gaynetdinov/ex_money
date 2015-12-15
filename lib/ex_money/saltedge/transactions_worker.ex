defmodule ExMoney.Saltedge.TransactionsWorker do
  use GenServer

  require Logger

  import Ecto.Query

  alias ExMoney.Repo
  alias ExMoney.Transaction
  alias ExMoney.TransactionInfo
  alias ExMoney.Account
  alias ExMoney.Category

  @interval 29 * 60 * 1000

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :transactions_worker)
  end

  def init(:ok) do
    accounts = Repo.all(Account)

    case accounts do
      [] -> :ignore
      accounts ->
        Enum.each(accounts, fn(account) ->
          Process.send_after(self(), {:fetch, account.saltedge_account_id}, 5000)
        end)

        {:ok, {}}
    end
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
