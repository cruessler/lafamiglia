# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :la_famiglia,
  ecto_repos: [LaFamiglia.Repo]

# Configures the endpoint
config :la_famiglia, LaFamigliaWeb.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: String.duplicate("abcdefgh", 8),
  render_errors: [accepts: ["html"]],
  pubsub_server: LaFamiglia.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :la_famiglia, game_speed: 1
config :la_famiglia, unit_speed: 1

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
