use Mix.Config

config :ex_money, ExMoney.Web.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :warn

# Configure your database
config :ex_money, ExMoney.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

config :ex_money, :saltedge,
  private_key_path: "test/support/fake_key"

import_config "test.secret.exs"
