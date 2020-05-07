defmodule LaFamiglia.Repo.Migrations.CreateReport do
  use Ecto.Migration

  def change do
    create table(:reports) do
      add :player_id, references(:players)

      add :title, :string
      add :data, :map
      add :read, :boolean

      add :delivered_at, :utc_datetime_usec

      timestamps
    end
  end
end
