defmodule LaFamiglia.CombatReport do
  import Ecto.Changeset

  alias LaFamiglia.Repo
  alias LaFamiglia.Report
  alias LaFamiglia.ReportData
  alias LaFamiglia.RelatedReportVilla

  def deliver!(origin, target, result) do
    report_for_attacker =
      Report.changeset(%Report{}, data_for(origin, result))
    report_for_defender =
      Report.changeset(%Report{}, data_for(target, result))

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

  defp data_for(villa, result) do
    report_data = struct(ReportData, Map.from_struct(result))

    %{title: title_for(villa, result),
      data: report_data,
      player_id: villa.player.id}
  end

  defp title_for(villa, result) do
    if villa == result.attacker.origin do
      "Attack on #{result.defender}"
    else
      "Attack from #{result.attacker.origin}"
    end
  end
end
