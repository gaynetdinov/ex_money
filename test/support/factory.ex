defmodule ExMoney.Factory do
  use ExMachina.Ecto, repo: ExMoney.Repo

  def user_factory do
    %ExMoney.User{
      name: Faker.Name.name,
      email: Faker.Internet.email,
      password: Faker.Lorem.word,
      saltedge_customer_id: Faker.Lorem.word,
      saltedge_id: sequence(:saltedge_id, &(&1)) + 1
    }
  end

  def login_factory do
    %ExMoney.Login{
      saltedge_login_id: sequence(:saltedge_login_id, &(&1)) + 1,
      user: build(:user)
    }
  end

  def account_factory do
    %ExMoney.Account {
      saltedge_account_id: sequence(:saltedge_account_id, &(&1)) + 1,
      login: build(:login),
      name: sequence(:account_name, &"account name #{(&1)}"),
      nature: "debit",
      balance: Decimal.new(10),
      currency_code: "EUR",
      user: build(:user)
    }
  end

  def accounts_balance_history do
    %ExMoney.AccountsBalanceHistory {
      account: build(:account),
      balance: Decimal.new(10)
    }
  end

  def transaction_factory do
    account = build(:account)

    %ExMoney.Transaction{
      saltedge_transaction_id: sequence(:saltedge_transaction_id, &(&1)) + 1,
      mode: "normal",
      status: "post",
      made_on: Ecto.Date.from_erl({2016, 09, 01}),
      amount: Decimal.new(10),
      currency_code: "EUR",
      description: "iban number date something",
      duplicated: false,
      saltedge_account_id: account.saltedge_account_id,
      account: account,
      user: build(:user),
      category: build(:category),
      transaction_info: build(:transaction_info)
    }
  end

  def transaction_info_factory do
    %ExMoney.TransactionInfo{}
  end

  def category_factory do
    %ExMoney.Category{
      name: sequence(:category_name, &("category-#{(&1)}"))
    }
  end

  def rule_factory do
    %ExMoney.Rule{
      account: build(:account),
      type: "assign_category",
      target_id: sequence(:target_id, &(&1)) + 1,
      pattern: "foo",
      priority: sequence(:priority, &(&1)) + 1
    }
  end
end
