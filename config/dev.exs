use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :ex_money, ExMoney.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  cache_static_lookup: false,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin"]]

# Watch static and templates for browser reloading.
config :ex_money, ExMoney.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

# ExMoney uses Postgres
config :ex_money, ExMoney.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10

config :ex_money, :login_logger_worker, :login_logger

# Put Saltedge credentials into dev.secret.exs
# config :ex_money,
#   saltedge_client_id: "your client id"
#   saltedge_service_secret: "your service secret"
# Also put database credentials into dev.descret.exs like this:
# config :ex_money, ExMoney.Repo,
#  username: "username",
#  password: "password",
#  database: "db_name",
#  hostname: "host"
import_config "dev.secret.exs"
