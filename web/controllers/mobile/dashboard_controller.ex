defmodule ExMoney.Mobile.DashboardController do
  use ExMoney.Web, :controller

  alias ExMoney.{Repo, Transaction, User, Account}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Mobile.Unauthenticated
  plug :put_layout, "mobile.html"

  def overview(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    last_login_at = user.last_login_at

    transactions = Transaction.recent
    |> Repo.all

    new_recent_transactions = Enum.filter(transactions, fn(tr) ->
      Ecto.DateTime.compare(tr.inserted_at, last_login_at) != :lt
    end)

    new_transaction_ids = Enum.map(new_recent_transactions, fn(tr) -> tr.id end)

    recent_transactions = Enum.group_by(transactions, fn(transaction) ->
      transaction.made_on
    end)
    |> Enum.sort(fn({date_1, _transactions}, {date_2, _transaction}) ->
      Ecto.Date.compare(date_1, date_2) != :lt
    end)

    accounts = Account.show_on_dashboard
    |> Repo.all
    |> Enum.reduce([], fn(account, acc) ->
      new_transactions = Transaction.new_since(last_login_at, account.id) |> Repo.all

      recent_diff = Enum.reduce(new_transactions, Decimal.new(0), fn(transaction, acc) ->
        Decimal.add(acc, transaction.amount)
      end)

      [Map.put(account, :recent_diff, recent_diff) | acc]
    end)

    render conn, :overview,
      recent_transactions: recent_transactions,
      accounts: accounts,
      new_transaction_ids: new_transaction_ids
  end
end
