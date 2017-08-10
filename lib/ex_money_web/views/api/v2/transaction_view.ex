defmodule ExMoney.Web.Api.V2.TransactionView do
  use ExMoney.Web, :view

  alias ExMoney.Web.Api.V2.TransactionView

  def render("recent.json", %{transactions: transactions}) do
    render_many(transactions, TransactionView, "transaction.json")
  end

  def render("transaction.json", %{transaction: transaction}) do
    %{
       id: transaction.id,
       made_on: transaction.made_on,
       amount: transaction.amount,
       amount_millicents: ExMoney.Money.to_millicents(transaction.amount),
       currency_code: transaction.currency_code,
       description: transaction.description,
       account_id: transaction.account_id,
       extra: transaction.extra,
       category: render_one(transaction.category, TransactionView, "category.json", as: :category)
     }
  end

  def render("category.json", %{category: category}) do
    %{
       id: category.id,
       name: category.name
     }
  end
end
