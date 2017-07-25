defmodule Mix.Tasks.ExMoney.MigrateTransactionsInfo do
  use Mix.Task
  import Mix.Ecto

  alias ExMoney.{Repo, Transaction, TransactionInfo}

  @shortdoc "Migrate TransactionsInfo table to 'extra' jsonb column in Transaction"

  def run(_args) do
    ensure_repo(ExMoney.Repo, [])
    ensure_started(ExMoney.Repo, [])

    infos = Repo.all(TransactionInfo)

    Enum.each infos, fn(info) ->
      info_map =
        info
        |> Map.from_struct()
        |> Map.drop([:id, :inserted_at, :__meta__, :updated_at, :transaction_id, :transaction])
        |> Enum.filter(fn {_, v} -> v != nil end)
        |> Enum.into(%{})

      transaction = Repo.get(Transaction, info.transaction_id)

      Transaction.update_changeset(transaction, %{extra: info_map})
      |> Repo.update
    end
  end
end
