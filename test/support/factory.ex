defmodule ExMoney.Factory do
  use ExMachina.Ecto, repo: ExMoney.Repo

  def factory(:user) do
    %ExMoney.User{
      name: Faker.Name.name,
      email: Faker.Internet.email,
      password: Faker.Lorem.word,
      saltedge_customer_id: Faker.Lorem.word
    }
  end

  def factory(:login) do
    %ExMoney.Login{
      saltedge_login_id: sequence(:saltedge_login_id, &(&1)),
      user: build(:user)
    }
  end
end
