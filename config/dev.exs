use Mix.Config

config :ex_money, ExMoney.Web.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  cache_static_lookup: false,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin", cd: Path.expand("../assets", __DIR__)]]

# Watch static and templates for browser reloading.
config :ex_money, ExMoney.Web.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{lib/ex_money_web/views/.*(ex)$},
      ~r{lib/ex_money_web/templates/.*(eex)$}
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :ex_money, ExMoney.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10

# Put Saltedge credentials into dev.secret.exs
# config :ex_money,
#   saltedge_client_id: "your client id"
#   saltedge_service_secret: "your service secret"
#
# Also put database credentials into dev.descret.exs like this:
# config :ex_money, ExMoney.Repo,
#  username: "username",
#  password: "password",
#  database: "db_name",
#  hostname: "host"
import_config "dev.secret.exs"
