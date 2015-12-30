defmodule LaFamiglia.CombatReport do
  alias LaFamiglia.Repo
  alias LaFamiglia.Report
  alias LaFamiglia.RelatedReportVilla

  def deliver!(origin, target, result) do
    report_for_attacker =
      Ecto.Changeset.change(%Report{}, title: "Attack",
                                       data: result,
                                       player_id: origin.player.id)
    report_for_defender =
      Ecto.Changeset.change(%Report{}, title: "Attack",
                                       data: result,
                                       player_id: target.player.id)

    report_for_attacker = Repo.insert!(report_for_attacker)
    report_for_defender = Repo.insert!(report_for_defender)

    RelatedReportVilla.changeset(%RelatedReportVilla{},
                                 %{related_report_id: report_for_attacker.id,
                                 villa_id: origin.id})
    |> Repo.insert!
    RelatedReportVilla.changeset(%RelatedReportVilla{},
                                 %{related_report_id: report_for_attacker.id,
                                 villa_id: target.id})
    |> Repo.insert!
    RelatedReportVilla.changeset(%RelatedReportVilla{},
                                 %{related_report_id: report_for_defender.id,
                                 villa_id: origin.id})
    |> Repo.insert!
    RelatedReportVilla.changeset(%RelatedReportVilla{},
                                 %{related_report_id: report_for_defender.id,
                                 villa_id: target.id})
    |> Repo.insert!
  end
end
