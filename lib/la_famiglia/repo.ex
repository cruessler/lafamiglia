defmodule LaFamiglia.Repo do
  use Ecto.Repo,
    otp_app: :la_famiglia,
    adapter: Ecto.Adapters.Postgres
end
