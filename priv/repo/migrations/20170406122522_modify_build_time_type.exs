defmodule LaFamiglia.Repo.Migrations.ModifyBuildTimeType do
  use Ecto.Migration

  def change do
    alter table(:building_queue_items) do
      modify :build_time, :integer
    end

    alter table(:unit_queue_items) do
      modify :build_time, :integer
    end
  end
end
