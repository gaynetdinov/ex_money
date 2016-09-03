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
end
