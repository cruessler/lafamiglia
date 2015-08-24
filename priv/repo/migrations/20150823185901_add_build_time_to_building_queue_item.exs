defmodule LaFamiglia.Repo.Migrations.AddBuildTimeToBuildingQueueItem do
  use Ecto.Migration

  def change do
    alter table(:building_queue_items) do
      add :build_time, :float
    end
  end
end
