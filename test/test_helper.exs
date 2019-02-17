ExUnit.start()
Application.ensure_all_started(:ex_machina)
Application.ensure_all_started(:bypass)
Faker.start()

Ecto.Adapters.SQL.Sandbox.mode(ExMoney.Repo, :manual)
