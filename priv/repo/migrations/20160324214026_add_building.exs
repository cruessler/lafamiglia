defmodule LaFamiglia.Repo.Migrations.AddBuilding do
  use Ecto.Migration

  def change do
    alter table(:villas) do
      add :building_6, :integer
    end
  end
end
