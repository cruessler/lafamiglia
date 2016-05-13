defmodule LaFamiglia.Repo.Migrations.CreateOccupation do
  use Ecto.Migration

  def change do
    create table(:occupations) do
      add :origin_id, references(:villas, on_delete: :delete_all)
      add :target_id, references(:villas, on_delete: :delete_all)

      add :succeeds_at, :datetime

      add :unit_1, :integer
      add :unit_2, :integer

      timestamps
    end

    create index(:occupations, [:origin_id], unique: true)
    create index(:occupations, [:target_id])
  end
end
