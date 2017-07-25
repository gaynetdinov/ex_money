defmodule ExMoney.Saltedge.TransactionsWorker do
  use GenServer

  require Logger

  alias ExMoney.{Repo, Transaction, Category, Account}

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: :transactions_worker)
  end

  def handle_call({:fetch_recent, saltedge_account_id}, _from, state) do
    account = Account.by_saltedge_account_id(saltedge_account_id) |> Repo.one
    last_transaction = find_last_transaction(saltedge_account_id)

    {:ok, stored_transactions, fetched_transactions} = fetch_recent_and_store(account, last_transaction)

    {:reply, {:ok, stored_transactions, fetched_transactions}, state}
  end

  def handle_call({:fetch_all, saltedge_account_id}, _from, state) do
    account = Account.by_saltedge_account_id(saltedge_account_id) |> Repo.one
    {:ok, stored_transactions, fetched_transactions} = fetch_all(account)

    {:reply, {:ok, stored_transactions, fetched_transactions}, state}
  end

  defp fetch_recent_and_store(account, nil) do
    Logger.info("There are no transactions in DB for account with id #{account.name}")
    to = Timex.local
    from = Timex.shift(to, months: -2)

    transactions = fetch_custom(account.saltedge_account_id, from, to, nil, [])

    stored_transactions = store(transactions, account)

    {:ok, stored_transactions, Enum.count(transactions)}
  end

  defp fetch_recent_and_store(account, last_transaction) do
    transactions = fetch_recent(account.saltedge_account_id, last_transaction.saltedge_transaction_id, [])
    |> List.flatten

    stored_transactions = store(transactions, account)

    {:ok, stored_transactions, Enum.count(transactions)}
  end

  defp fetch_recent(saltedge_account_id, from_id, acc) do
    endpoint = "transactions?account_id=#{saltedge_account_id}&from_id=#{from_id}"

    {:ok, response} = ExMoney.Saltedge.Client.request(:get, endpoint)

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

  defp fetch_all(account) do
    to = Timex.local
    from = Timex.shift(to, months: -1)

    transactions = fetch_all(account.saltedge_account_id, from, to, [])

    stored_transactions = store(transactions, account)

    {:ok, stored_transactions, Enum.count(transactions)}
  end

  defp fetch_all(saltedge_account_id, from, to, acc) do
    case fetch_custom(saltedge_account_id, from, to, nil, []) do
      [] -> List.flatten(acc)
      transactions_chunk ->
        new_from = Timex.shift(from, months: -1)
        new_to = Timex.shift(from, days: -1)
        fetch_all(saltedge_account_id, new_from, new_to, [transactions_chunk | acc])
    end
  end

  defp fetch_custom(saltedge_account_id, from, to, next_id, acc) do
    from_str = date_to_string(from)
    to_str = date_to_string(to)
    endpoint = "transactions?account_id=#{saltedge_account_id}&from_date=#{from_str}&to_date=#{to_str}"

    endpoint = if next_id do
      endpoint <> "&from_id=#{next_id}"
    else
      endpoint
    end

    {:ok, response} = ExMoney.Saltedge.Client.request(:get, endpoint)

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

  defp store(transactions, account) do
    Enum.reduce(transactions, 0, fn(se_tran, acc) ->
      se_tran = Map.put(se_tran, "saltedge_transaction_id", se_tran["id"])
      se_tran = Map.put(se_tran, "saltedge_account_id", se_tran["account_id"])
      se_tran = Map.put(se_tran, "user_id", account.user_id)
      se_tran = Map.drop(se_tran, ["id", "account_id"])
      se_tran = Map.put(se_tran, "account_id", account.id)

      existing_transaction = Transaction.
        by_saltedge_transaction_id(se_tran["saltedge_transaction_id"])
        |> Repo.one

      if !existing_transaction and !se_tran["duplicated"] do
        se_tran = set_category_id(se_tran)

        changeset = Transaction.changeset(%Transaction{}, se_tran)
        {:ok, inserted_transaction} = Repo.transaction fn ->
          Repo.insert!(changeset)
        end
        GenServer.cast(:rule_processor, {:process, inserted_transaction.id})

        acc + 1
      else
        acc
      end
    end)
  end

  defp set_category_id(transaction) do
    category = find_or_create_category(transaction["category"])

    Map.put(transaction, "category_id", category.id)
  end

  defp find_or_create_category(name) do
    case Category.by_name_with_hidden(name) |> Repo.one do
      nil ->
        changeset = Category.changeset(%Category{}, %{name: name})
        Repo.insert!(changeset)

      existing_category -> existing_category
    end
  end

  defp date_to_string(date) do
    {:ok, str_date} = Timex.format(date, "%Y-%m-%d", :strftime)
    str_date
  end

  defp find_last_transaction(saltedge_account_id) do
    # FIXME: set last_transaction_id in cache during import
    Transaction.newest(saltedge_account_id)
    |> Repo.one
  end
end
