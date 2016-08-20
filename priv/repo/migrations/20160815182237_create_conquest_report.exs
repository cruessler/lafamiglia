defmodule LaFamiglia.Repo.Migrations.CreateConquestReport do
  use Ecto.Migration

  def change do
    create table(:conquest_reports) do
      add :report_id, references(:reports, on_delete: :delete_all)

      add :target_id, references(:villas, on_delete: :delete_all)
    end
  end
end
