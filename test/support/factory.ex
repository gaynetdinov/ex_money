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
end
