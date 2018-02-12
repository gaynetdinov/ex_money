defmodule Mix.Tasks.ExMoney.AccountsHistoryBalanceState do
  use Mix.Task
  import Mix.Ecto
  import Ecto.Query, warn: false

  alias ExMoney.{Repo, Accounts.BalanceHistory}

  @shortdoc "Move balance history entries into `state` map field to reduce number of rows"

  def run(_args) do
    ensure_repo(ExMoney.Repo, [])
    ensure_started(ExMoney.Repo, [])

    query = from h in BalanceHistory,
      group_by: fragment("inserted_at::timestamp::date"),
      select: %{
        min_id: min(h.id),
        grouped_json: fragment("json_agg(json_build_object('id', id, 'account_id', account_id, 'balance', balance))")
      }

    h = Repo.all(query)

    Enum.each h, fn(%{min_id: id, grouped_json: grouped_json}) ->
      accounts_state = Enum.reduce grouped_json, %{}, fn(row, acc) ->
        Map.put(acc, row["account_id"], row["balance"])
      end

      ids_to_remove = Enum.reduce grouped_json, [], fn(row, acc) ->
        if row["id"] != id do
          [row["id"] | acc]
        else
          acc
        end
      end

      Repo.get(BalanceHistory, id)
      |> BalanceHistory.changeset(%{state: accounts_state})
      |> Repo.update!

      (from h in BalanceHistory, where: h.id in ^ids_to_remove) |> Repo.delete_all
    end
  end
end
