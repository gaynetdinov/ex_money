ExUnit.start
Application.ensure_all_started(:ex_machina)
Faker.start

Ecto.Adapters.SQL.Sandbox.mode(ExMoney.Repo, :manual)
