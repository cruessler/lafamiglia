use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :la_famiglia, LaFamiglia.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  cache_static_lookup: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :la_famiglia, LaFamiglia.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
# config :logger, :console, format: "[$level] $message\n"

# Configure your database
config :la_famiglia, LaFamiglia.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "la_famiglia",
  password: "la_famiglia",
  database: "la_famiglia_dev",
  pool_size: 10

config :la_famiglia, game_speed: 2
config :la_famiglia, unit_speed: 200
