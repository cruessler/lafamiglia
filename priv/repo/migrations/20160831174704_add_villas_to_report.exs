defmodule LaFamiglia.Repo.Migrations.AddVillasToReport do
  use Ecto.Migration

  def change do
    alter table(:reports) do
      add :origin_id, references(:villas, on_delete: :delete_all)
      add :target_id, references(:villas, on_delete: :delete_all)
    end
  end
end
