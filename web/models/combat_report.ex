defmodule LaFamiglia.CombatReport do
  alias LaFamiglia.Repo
  alias LaFamiglia.Report
  alias LaFamiglia.ReportData
  alias LaFamiglia.RelatedReportVilla

  def deliver!(origin, target, result) do
    report_data = struct(ReportData, Map.from_struct(result))

    report_for_attacker =
      Ecto.Changeset.change(%Report{}, title: title_for(origin, result),
                                       data: report_data,
                                       player_id: origin.player.id)
    report_for_defender =
      Ecto.Changeset.change(%Report{}, title: title_for(target, result),
                                       data: report_data,
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

  defp title_for(villa, result) do
    if villa == result.attacker.origin do
      "Attack on #{result.defender}"
    else
      "Attack from #{result.attacker.origin}"
    end
  end
end
