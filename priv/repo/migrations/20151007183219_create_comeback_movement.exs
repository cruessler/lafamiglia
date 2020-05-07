defmodule LaFamiglia.Repo.Migrations.CreateComebackMovement do
  use Ecto.Migration

  def change do
    create table(:comeback_movements) do
      add :origin_id, references(:villas)
      add :target_id, references(:villas)

      add :unit_1, :integer
      add :unit_2, :integer

      add :resource_1, :integer
      add :resource_2, :integer
      add :resource_3, :integer

      add :arrives_at, :utc_datetime_usec

      timestamps
    end

    create index(:comeback_movements, [:origin_id])
    create index(:comeback_movements, [:target_id])
  end
end
