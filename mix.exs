defmodule LaFamiglia.Mixfile do
  use Mix.Project

  def project do
    [app: :la_famiglia,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {LaFamiglia, []},
     applications: applications(Mix.env)]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:dev),  do: ["lib", "web", "test/support"]
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp applications(:dev),  do: applications(:test)
  defp applications(:test), do: applications(:all)
  defp applications(_) do
    [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
     :phoenix_ecto, :postgrex, :comeonin, :ex_machina, :tzdata]
  end


  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 1.2"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:ecto, "~> 2.1"},
     {:postgrex, "~> 0.13"},
     {:poison, "~> 2.0", override: true},
     {:phoenix_html, "~> 2.5"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     # https://github.com/elixircnx/comeonin
     {:comeonin, "~> 2.0"},
     {:cowboy, "~> 1.0"},
     # https://github.com/thoughtbot/ex_machina/
     {:ex_machina, "~> 1.0"},
     {:distillery, "~> 0.9"},
     {:gettext, "~> 0.10"},
     {:timex, "~> 3.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"],
     "integration.setup": ["ecto.drop", "ecto.create --quiet", "ecto.migrate"],
     "integration": ["la_famiglia.server"]]
  end
end
