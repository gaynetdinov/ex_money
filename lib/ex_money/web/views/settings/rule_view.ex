defmodule ExMoney.Web.Settings.RuleView do
  use ExMoney.Web, :view

  def target_name("assign_category", target_id, categories, _accounts) do
    case categories[target_id] do
      nil -> "Stale target, remove this rule"
      category -> "Category: #{category.humanized_name}"
    end
  end

  def target_name("withdraw_to_cash", target_id, _categories, accounts) do
    case accounts[target_id] do
      nil -> "Stale target, remove this rule"
      account -> "Account: #{account.name}"
    end
  end
end
