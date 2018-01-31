use Mix.Config

config :ex_money, ExMoney.Web.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: System.get_env("HOME_URL"), port: 443],
  check_origin: ["https://#{System.get_env("HOME_URL")}"],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Do not print debug messages in production
config :logger, level: :debug

config :ex_money, :login_logger_worker,
  [name: ExMoney.Saltedge.LoginLogger, enabled: false]

config :ex_money,
  saltedge_client_id: System.get_env("CLIENT_ID"),
  saltedge_service_secret: System.get_env("SERVICE_SECRET")

config :ex_money, ExMoney.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: 2
