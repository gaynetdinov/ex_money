# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :ex_money, ExMoney.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "bYD4acbloFnRjQ287+iQa1wS93y9FCrtomk0+kuIGgSNRClW8HYR745TUPT/bGFj",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: ExMoney.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
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
  level: :info

config :logger, :error,
  path: "log/error.log",
  level: :error

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

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
  serializer: ExMoney.Guardian.Serializer
