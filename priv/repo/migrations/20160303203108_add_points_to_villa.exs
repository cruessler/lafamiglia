defmodule LaFamiglia.Repo.Migrations.AddPointsToVilla do
  use Ecto.Migration

  def change do
    alter table(:villas) do
      add :points, :integer
    end
  end
end
