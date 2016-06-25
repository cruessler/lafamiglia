defmodule LaFamiglia.CombatReport do
  import Ecto.Changeset

  alias Ecto.Multi

  alias LaFamiglia.Combat
  alias LaFamiglia.Report
  alias LaFamiglia.ReportData

  @spec deliver(Combat.t) :: Multi.t
  def deliver(combat) do
    Multi.new
    |> Multi.insert(:report_for_origin, report_for(combat.attack.origin, combat))
    |> Multi.insert(:report_for_target, report_for(combat.attack.target, combat))
  end

  defp report_for(villa, combat) do
    %Report{}
    |> Report.changeset(data_for(villa, combat))
    |> put_assoc(:related_villas, [combat.attack.origin, combat.attack.target])
  end

  defp data_for(villa, %{result: result} = combat) do
    report_data = struct(ReportData, Map.from_struct(result))

    %{title: title_for(villa, combat),
      data: report_data,
      player_id: villa.player.id}
  end

  defp title_for(villa, %{attack: attack}) do
    if villa == attack.origin do
      "Attack on #{attack.target}"
    else
      "Attack from #{attack.origin}"
    end
  end
end
