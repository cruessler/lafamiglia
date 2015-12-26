defmodule LaFamiglia.CombatReport do
  alias LaFamiglia.Repo
  alias LaFamiglia.Report

  def deliver!(origin, target, result) do
    report_for_attacker =
      Ecto.Changeset.change(%Report{}, title: "Attack",
                                       data: result,
                                       player_id: origin.player.id)
    report_for_defender =
      Ecto.Changeset.change(%Report{}, title: "Attack",
                                       data: result,
                                       player_id: target.player.id)

    Repo.insert(report_for_attacker)
    Repo.insert(report_for_defender)
  end
end
