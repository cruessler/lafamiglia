defmodule LaFamiglia.Repo.Migrations.CreatePlayer do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string
      add :email, :string
      add :hashed_password, :string

      add :points, :integer

      timestamps
    end
  end
end
