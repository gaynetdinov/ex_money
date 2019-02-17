use Mix.Config

config :ex_money, ExMoney.Web.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "bYD4acbloFnRjQ287+iQa1wS93y9FCrtomk0+kuIGgSNRClW8HYR745TUPT/bGFj",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: ExMoney.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :ex_money,
  ecto_repos: [ExMoney.Repo],
  hour_to_sleep: 23

config :logger,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  backends: [
    :console,
    {LoggerFileBackend, :info},
    {LoggerFileBackend, :error}
  ]

config :logger, :info,
  path: "log/info.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module]

config :logger, :error,
  path: "log/error.log",
  level: :error,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module]

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :ex_money, config_module: Guardian.JWT

config :guardian, Guardian,
  issuer: "ExMoney",
  ttl: { 30, :days },
  verify_issuer: true,
  secret_key: "showmethemoney",
  serializer: ExMoney.Guardian.Serializer,
  hooks: GuardianDb

config :guardian_db, GuardianDb,
  repo: ExMoney.Repo

config :ex_money, :saltedge,
  base_url: "https://www.saltedge.com/api/v4",
  private_key_path: "lib/saltedge_private.pem"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

import_config "#{Mix.env}.exs"
