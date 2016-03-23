defmodule LaFamiglia.Repo.Migrations.AddThreeBuildings do
  use Ecto.Migration

  def change do
    alter table(:villas) do
      add :building_3, :integer
      add :building_4, :integer
      add :building_5, :integer
    end
  end
end
