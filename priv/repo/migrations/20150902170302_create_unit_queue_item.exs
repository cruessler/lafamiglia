defmodule LaFamiglia.Repo.Migrations.CreateUnitQueueItem do
  use Ecto.Migration

  def change do
    create table(:unit_queue_items) do
      add :villa_id, references(:villas)

      add :unit_id, :integer
      add :number, :integer
      add :build_time, :float
      add :completed_at, :utc_datetime_usec

      timestamps
    end

    create index(:unit_queue_items, [:villa_id])
    create index(:unit_queue_items, [:completed_at])

    alter table(:villas) do
      add :supply, :integer
      add :max_supply, :integer

      add :unit_1, :integer
      add :unit_2, :integer
    end
  end
end
