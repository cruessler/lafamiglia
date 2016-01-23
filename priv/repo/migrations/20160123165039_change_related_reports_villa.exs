defmodule LaFamiglia.Repo.Migrations.ChangeRelatedReportsVilla do
  use Ecto.Migration

  def change do
    # Using `alter` and `modify` makes MySQL complain about a duplicate key.
    drop table(:related_reports_villas)

    create table(:related_reports_villas, primary_key: false) do
      add :related_report_id, references(:reports, on_delete: :delete_all)
      add :villa_id, references(:villas, on_delete: :delete_all)

      timestamps
    end

    create index(:related_reports_villas, [:related_report_id])
    create index(:related_reports_villas, [:villa_id])
  end
end
