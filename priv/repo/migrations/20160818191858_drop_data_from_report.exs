defmodule LaFamiglia.Repo.Migrations.DropDataFromReport do
  use Ecto.Migration

  def up do
    alter table(:reports) do
      remove :data
    end
  end

  def down do
    alter table(:reports) do
      add :data, :map
    end
  end
end
