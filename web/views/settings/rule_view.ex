defmodule ExMoney.Settings.RuleView do
  use ExMoney.Web, :view

  def target_name("assign_category", target_id, categories, _accounts) do
    "Category: #{categories[target_id].name}"
  end

  def target_name("withdraw_to_cash", target_id, _categories, accounts) do
    "Account: #{accounts[target_id].name}"
  end
end
