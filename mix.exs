defmodule ExMoney.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_money,
     version: "0.0.1",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  def application do
    [mod: {ExMoney.Application, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger,
                    :phoenix_ecto, :postgrex, :httpoison, :tzdata]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:httpoison, "~> 0.12"},
      {:guardian, "~> 0.14"},
      {:guardian_db, "~> 0.8"},
      {:comeonin, "~> 3.1"},
      {:ex_machina, "~> 2.0"},
      {:faker, "~> 0.7", only: :test},
      {:logger_file_backend, "0.0.10"},
      {:timex, "~> 3.1"},
      {:jason, "~> 1.0"},
      {:bypass, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
