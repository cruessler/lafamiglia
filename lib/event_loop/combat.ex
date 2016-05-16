defmodule LaFamiglia.Combat do
  alias Ecto.Changeset
  alias Ecto.Multi

  alias LaFamiglia.{Building, Resource, Unit}
  alias LaFamiglia.Villa
  alias LaFamiglia.{AttackMovement, ComebackMovement}
  alias LaFamiglia.CombatResult
  alias LaFamiglia.Combat.AfterCombat
  alias LaFamiglia.CombatReport

  alias __MODULE__

  defstruct [:attack, :target_changeset, :result]
  @type t :: %Combat{
    attack: AttackMovement.t,
    target_changeset: Changeset.t,
    result: CombatResult.t
  }

  @unit_for_occupation Application.get_env(:la_famiglia, :unit_for_occupation)

  def new(attack) do
    %Combat{attack: attack}
  end

  def calculate(%Combat{attack: attack} = combat) do
    target_changeset =
      Changeset.change(attack.target)
      |> Villa.process_virtually_until(attack.arrives_at)

    result = Combat.calculate(attack, Changeset.apply_changes(target_changeset))

    %{combat | target_changeset: target_changeset, result: result}
  end

  def to_multi(%Combat{} = combat) do
    %{attack: attack, target_changeset: target_changeset, result: result} = combat

    origin_changeset =
      Changeset.change(attack.origin)
      |> Villa.subtract_supply(result.attacker_supply_loss)
    target_changeset =
      target_changeset
      |> Villa.subtract_units(result.defender_losses)
      |> Villa.subtract_supply(result.defender_supply_loss)
      |> Villa.subtract_resources(result.resources_plundered)

    multi =
      Multi.new
      |> Multi.run(:deliver_report, fn(_) ->
        CombatReport.deliver!(attack.origin, attack.target, result)

        {:ok, nil}
      end)
      |> Multi.delete(:attack, attack)
      |> Multi.update(:origin, origin_changeset)
      |> Multi.update(:target, target_changeset)
      |> append_comeback(combat)
  end

  defp append_comeback(multi, %Combat{result: %{attacker_survived?: true}} = combat) do
    changeset = ComebackMovement.from_combat(combat.attack, combat.result)

    multi
    |> Multi.insert(:comeback, changeset)
    |> Multi.run(:send_to_queue, fn(%{comeback: comeback}) ->
      LaFamiglia.EventQueue.cast({:new_event, comeback})

      {:ok, nil}
    end)
  end
  defp append_comeback(multi, _), do: multi

  def calculate(attacker, defender) do
    %CombatResult{
      attacker: attacker,
      defender: defender,
      attacker_before_combat: Unit.filter(attacker),
      defender_before_combat: Unit.filter(defender)
      }
      |> calculate_combat_values
      |> calculate_winner
      |> calculate_percent_loss
      |> calculate_losses
      |> calculate_results_in_occupation
      |> calculate_plundered_resources
  end

  defp calculate_combat_values(result) do
    attack_value = Enum.reduce Unit.all, 0, fn(u, acc) ->
      acc + Map.get(result.attacker_before_combat, u.key) * u.attack
    end
    defense_value = Enum.reduce Unit.all, 0, fn(u, acc) ->
      acc + Map.get(result.defender_before_combat, u.key) * u.defense
    end
    defense_value = Enum.reduce Building.all, defense_value, fn(b, acc) ->
      acc + b.defense.(Map.get(result.defender, b.key))
    end

    %{result |
      attack_value: attack_value,
      defense_value: defense_value}
  end

  defp calculate_winner(result) do
    winner = if result.attack_value > result.defense_value, do: :attacker, else: :defender

    %{result | winner: winner}
  end

  defp calculate_percent_loss(%CombatResult{winner: :attacker} = result) do
    %{result |
      attacker_percent_loss: :math.pow(result.defense_value / result.attack_value, 1.5),
      defender_percent_loss: 1}
  end
  defp calculate_percent_loss(%CombatResult{winner: :defender} = result) do
    %{result |
      attacker_percent_loss: 1,
      defender_percent_loss: :math.pow(result.attack_value / result.defense_value, 1.5)}
  end

  defp calculate_losses(result) do
    attacker_losses =
      Unit.multiply(result.attacker_before_combat, result.attacker_percent_loss)
    defender_losses =
      Unit.multiply(result.defender_before_combat, result.defender_percent_loss)

    attacker_supply_loss = Unit.supply(attacker_losses)
    defender_supply_loss = Unit.supply(defender_losses)

    attacker_after_combat =
      Unit.subtract(result.attacker_before_combat, attacker_losses)
    defender_after_combat =
      Unit.subtract(result.defender_before_combat, defender_losses)

    attacker_survived = Enum.any?(attacker_after_combat, fn({_, n}) -> n > 0 end)

    %{result |
      attacker_losses: attacker_losses,
      defender_losses: defender_losses,
      attacker_supply_loss: attacker_supply_loss,
      defender_supply_loss: defender_supply_loss,
      attacker_after_combat: attacker_after_combat,
      defender_after_combat: defender_after_combat,
      attacker_survived?: attacker_survived}
  end

  defp calculate_results_in_occupation(result) do
    results_in_occupation =
      result.attacker_after_combat[@unit_for_occupation] > 0

    %{result | results_in_occupation?: results_in_occupation}
  end

  defp calculate_plundered_resources(%CombatResult{attacker_survived?: true} = result) do
    load =
      for({k, n} <- result.attacker_after_combat, do: Unit.get(k).load * n)
      |> Enum.sum

    resources_plundered =
      Resource.filter(result.defender)
      |> AfterCombat.plunder(load)

    %{result | resources_plundered: resources_plundered}
  end
  defp calculate_plundered_resources(result), do: %{result | resources_plundered: %{}}
end
