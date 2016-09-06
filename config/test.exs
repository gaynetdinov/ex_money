use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_money, ExMoney.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :ex_money, ExMoney.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

config :ex_money, :login_logger_worker,
  [name: ExMoney.Saltedge.Test.LoginLogger, enabled: true]

import_config "test.secret.exs"
