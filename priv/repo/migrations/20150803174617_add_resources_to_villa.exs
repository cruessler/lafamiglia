defmodule LaFamiglia.Repo.Migrations.AddResourcesToVilla do
  use Ecto.Migration

  def change do
    alter table(:villas) do
      add :resource_1, :float
      add :resource_2, :float
      add :resource_3, :float

      add :storage_capacity, :integer

      add :processed_until, :utc_datetime_usec
    end
  end
end
