defmodule LaFamiglia.Repo.Migrations.DropDataFromReport do
  use Ecto.Migration

  def change do
    alter table(:reports) do
      remove :data
    end
  end
end
