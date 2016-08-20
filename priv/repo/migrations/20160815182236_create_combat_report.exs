defmodule LaFamiglia.Repo.Migrations.CreateCombatReport do
  use Ecto.Migration

  def change do
    create table(:combat_reports) do
      add :report_id, references(:reports, on_delete: :delete_all)

      add :attacker_before_combat, :map
      add :attacker_losses, :map
      add :defender_before_combat, :map
      add :defender_losses, :map
      add :resources_plundered, :map
      add :results_in_occupation, :boolean
      add :attacker_wins, :boolean
    end
  end
end
