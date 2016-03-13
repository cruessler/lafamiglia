defmodule LaFamiglia.Repo.Migrations.SplitProcessedUntil do
  use Ecto.Migration

  def change do
    alter table(:villas) do
      add :resources_gained_until, :datetime
      add :units_recruited_until, :datetime

      remove :processed_until
    end
  end
end
