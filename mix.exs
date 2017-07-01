defmodule ExMoney.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_money,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  def application do
    [mod: {ExMoney, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger,
                    :phoenix_ecto, :postgrex, :httpoison, :tzdata]]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [
      {:phoenix, "~> 1.2"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.9"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:cowboy, "~> 1.0"},
      {:httpoison, "~> 0.12"},
      {:guardian, "~> 0.14"},
      {:guardian_db, "~> 0.8"},
      {:comeonin, "~> 3.1"},
      {:ex_machina, "~> 2.0"},
      {:faker, "~> 0.7", only: :test},
      {:logger_file_backend, "0.0.10"},
      {:timex, "~> 3.1"},
      {:bypass, "~> 0.2", only: :test}
    ]
  end

  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
