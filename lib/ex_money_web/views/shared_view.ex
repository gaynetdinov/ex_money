defmodule ExMoney.Web.SharedView do
  use ExMoney.Web, :view
  alias ExMoney.Transaction

  def translate_error({message, values}) do
    Enum.reduce values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end

  def translate_error(message), do: message

  def sort_by_inserted_at(transactions) do
    Enum.sort(transactions, fn(tr_1, tr_2) ->
      NaiveDateTime.compare(tr_1.inserted_at, tr_2.inserted_at) != :lt
    end)
  end

  def description(%Transaction{extra: nil} = transaction) do
    transaction.description
  end

  def description(transaction) do
    transaction.extra["payee"]
  end

  def category_name(nil), do: ""

  def category_name(category) do
    category.humanized_name
  end

  def account_balance(_date, _, nil), do: ""
  def account_balance(date, account_balance, account) do
    date = to_string(date)
    case account_balance[date] do
      nil -> ""
      balance -> "#{balance} #{account.currency_label}"
    end
  end
end
