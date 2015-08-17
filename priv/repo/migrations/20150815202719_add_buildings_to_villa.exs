defmodule LaFamiglia.Repo.Migrations.AddBuildingsToVilla do
  use Ecto.Migration

  def change do
    alter table(:villas) do
      add :building_1, :integer
      add :building_2, :integer
    end
  end
end
