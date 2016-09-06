defmodule LaFamiglia.CombatReport do
  use LaFamiglia.Web, :model

  import Ecto.Changeset

  alias Ecto.Multi

  alias LaFamiglia.Combat
  alias LaFamiglia.Report

  alias __MODULE__

  schema "combat_reports" do
    belongs_to :report, Report

    embeds_one :attacker_before_combat, Report.Schema.Units
    embeds_one :attacker_losses, Report.Schema.Units
    embeds_one :defender_before_combat, Report.Schema.Units
    embeds_one :defender_losses, Report.Schema.Units
    embeds_one :resources_plundered, Report.Schema.Resources

    field :results_in_occupation, :boolean
    field :attacker_wins, :boolean
  end

  @spec deliver(Combat.t) :: Multi.t
  def deliver(combat) do
    Multi.new
    |> Multi.insert(:report_for_origin, report_for(combat.attack.origin, combat))
    |> Multi.insert(:report_for_target, report_for(combat.attack.target, combat))
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:results_in_occupation, :attacker_wins])
    |> cast_embed(:attacker_before_combat)
    |> cast_embed(:attacker_losses)
    |> cast_embed(:defender_before_combat)
    |> cast_embed(:defender_losses)
    |> cast_embed(:resources_plundered)
  end

  defp report_for(villa, combat) do
    combat_report =
      %CombatReport{}
      |> changeset(Map.from_struct(combat.result))

    %Report{}
    |> Report.changeset(%{title: title_for(villa, combat)})
    |> put_assoc(:combat_report, combat_report)
    |> put_assoc(:player, villa.player)
    |> put_assoc(:origin, combat.attack.origin)
    |> put_assoc(:target, combat.attack.target)
  end

  defp title_for(villa, %{attack: attack}) do
    if villa == attack.origin do
      "Attack on #{attack.target}"
    else
      "Attack from #{attack.origin}"
    end
  end
end
