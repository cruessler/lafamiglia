use Mix.Config

# We run a server for use by puppeteer.
config :la_famiglia, LaFamigliaWeb.Endpoint,
  http: [port: 4001],
  server: true

# Configure your database
config :la_famiglia, LaFamiglia.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "la_famiglia_test",
  password: "la_famiglia_test",
  database: "la_famiglia_test"
