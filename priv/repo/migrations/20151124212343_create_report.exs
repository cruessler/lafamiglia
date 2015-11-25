defmodule LaFamiglia.Repo.Migrations.CreateReport do
  use Ecto.Migration

  def change do
    create table(:reports) do
      add :player_id, references(:players)

      add :title, :string
      add :data, :map
      add :read, :boolean

      add :delivered_at, :datetime

      timestamps
    end
  end
end
