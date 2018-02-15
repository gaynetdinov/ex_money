defmodule ExMoney.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ExMoney.Repo

  alias ExMoney.Accounts.BalanceHistory

  def get_account_history_balance(from, to) do
    {:ok, from} = Date.from_iso8601(from)
    erl_from = Date.to_erl(from)
    {:ok, naive_from} = NaiveDateTime.from_erl({erl_from, {0, 0, 0}})

    {:ok, to} = Date.from_iso8601(to)
    erl_to = Date.to_erl(to)
    {:ok, naive_to} = NaiveDateTime.from_erl({erl_to, {0, 0, 0}})

    query =
      from h in BalanceHistory,
        where: h.inserted_at >= ^naive_from,
        where: h.inserted_at <= ^naive_to

    Repo.all(query)
  end
end
