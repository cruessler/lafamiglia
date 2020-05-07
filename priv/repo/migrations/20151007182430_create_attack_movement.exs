defmodule LaFamiglia.Repo.Migrations.CreateAttackMovement do
  use Ecto.Migration

  def change do
    create table(:attack_movements) do
      add :origin_id, references(:villas)
      add :target_id, references(:villas)

      add :unit_1, :integer
      add :unit_2, :integer

      add :arrives_at, :utc_datetime_usec

      timestamps
    end

    create index(:attack_movements, [:origin_id])
    create index(:attack_movements, [:target_id])
  end
end
