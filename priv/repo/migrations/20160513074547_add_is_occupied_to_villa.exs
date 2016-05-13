defmodule LaFamiglia.Repo.Migrations.AddIsOccupiedToVilla do
  use Ecto.Migration

  def change do
    alter table(:villas) do
      add :is_occupied, :boolean
    end
  end
end
