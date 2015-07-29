defmodule LaFamiglia.Repo.Migrations.CreateVilla do
  use Ecto.Migration

  def change do
    create table(:villas) do
      add :name, :string
      add :x, :integer
      add :y, :integer

      add :player_id, references(:players)

      timestamps
    end

    create index(:villas, [ :x, :y ], unique: true)
  end
end
