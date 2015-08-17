defmodule LaFamiglia.Repo.Migrations.CreateBuildingQueueItem do
  use Ecto.Migration

  def change do
    create table(:building_queue_items) do
      add :villa_id, references(:villas)
      add :building_id, :integer
      add :completed_at, :datetime

      timestamps
    end

    create index(:building_queue_items, [:villa_id])
    create index(:building_queue_items, [:completed_at])
  end
end
