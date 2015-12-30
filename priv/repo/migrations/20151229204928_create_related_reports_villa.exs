defmodule LaFamiglia.Repo.Migrations.CreateRelatedReportsVilla do
  use Ecto.Migration

  def change do
    create table(:related_reports_villas, primary_key: false) do
      add :related_report_id, references(:reports)
      add :villa_id, references(:villas)

      timestamps
    end

    create index(:related_reports_villas, [:related_report_id])
    create index(:related_reports_villas, [:villa_id])
  end
end
