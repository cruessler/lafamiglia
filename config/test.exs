use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :la_famiglia, LaFamiglia.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :la_famiglia, LaFamiglia.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "la_famiglia",
  password: "la_famiglia",
  database: "la_famiglia_test",
  # Use a sandbox for transactional testing
  pool: Ecto.Adapters.SQL.Sandbox
