defmodule LaFamiglia.Repo.Migrations.SplitProcessedUntil do
  use Ecto.Migration

  def change do
    alter table(:villas) do
      add :resources_gained_until, :utc_datetime_usec
      add :units_recruited_until, :utc_datetime_usec

      remove :processed_until
    end
  end
end
