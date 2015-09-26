defmodule LaFamiglia.Mixfile do
  use Mix.Project

  def project do
    [app: :la_famiglia,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {LaFamiglia, []},
     applications: applications(Mix.env)]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp applications(:test), do: applications(:all) ++ [:blacksmith, :faker]
  defp applications(_),     do: [:phoenix, :phoenix_html, :cowboy, :logger,
                                 :phoenix_ecto, :mariaex, :comeonin]


  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 0.17"},
     {:phoenix_ecto, "~> 1.1"},
     {:ecto, "~> 1.0"},
     {:mariaex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.0"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     # https://github.com/elixircnx/comeonin
     {:comeonin, "~> 1.0"},
     {:cowboy, "~> 1.0"},
     # http://icanmakeitbetter.com/elixir-testing-blacksmith/
     # https://github.com/batate/blacksmith/
     {:blacksmith, "~> 0.1", only: :test},
     # https://github.com/igas/faker/
     {:faker, "~> 0.5", only: :test}]
  end
end
