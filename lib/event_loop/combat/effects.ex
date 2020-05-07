defmodule LaFamiglia.Combat.Effects do
  alias Ecto.Changeset
  alias Ecto.Multi

  alias LaFamiglia.Villa
  alias LaFamiglia.ComebackMovement
  alias LaFamiglia.Combat
  alias LaFamiglia.Occupation
  alias LaFamiglia.CombatReport

  def to_multi(
    %Combat{attack: %{target: %{is_occupied: true}},
            result: %{results_in_occupation?: true}} = combat)
  do
    %{attack: attack, result: result} = combat

    occupation_multi = Occupation.from_combat(combat)

    origin_changeset =
      Changeset.change(attack.origin)
      |> Villa.subtract_supply(result.attacker_supply_loss)
    target_changeset =
      attack.target
      |> Villa.process_virtually_until(attack.arrives_at)
      |> Villa.subtract_resources(result.resources_plundered)
      |> Changeset.put_change(:is_occupied, true)
    origin_of_occupation_changeset =
      Changeset.change(attack.target.occupation.origin)
      |> Villa.subtract_supply(result.defender_supply_loss)

    Multi.new
    |> Multi.append(CombatReport.deliver(combat))
    |> Multi.delete(:attack, attack)
    |> Multi.update(:origin, origin_changeset)
    |> Multi.update(:target, target_changeset)
    |> Multi.update(:origin_of_occupation, origin_of_occupation_changeset)
    |> Multi.delete(:occupation, attack.target.occupation)
    |> Multi.append(occupation_multi)
    |> notify_queue
  end
  def to_multi(%Combat{result: %{results_in_occupation?: true}} = combat) do
    %{attack: attack, result: result} = combat

    occupation_multi = Occupation.from_combat(combat)

    origin_changeset =
      Changeset.change(attack.origin)
      |> Villa.subtract_supply(result.attacker_supply_loss)
    target_changeset =
      attack.target
      |> Villa.process_virtually_until(attack.arrives_at)
      |> Villa.subtract_units(result.defender_losses)
      |> Villa.subtract_supply(result.defender_supply_loss)
      |> Changeset.put_change(:is_occupied, true)

    Multi.new
    |> Multi.append(CombatReport.deliver(combat))
    |> Multi.delete(:attack, attack)
    |> Multi.update(:origin, origin_changeset)
    |> Multi.update(:target, target_changeset)
    |> Multi.append(occupation_multi)
    |> notify_queue
  end
  def to_multi(%Combat{attack: %{target: %{is_occupied: true}}} = combat) do
    %{attack: attack, result: result} = combat

    origin_changeset =
      Changeset.change(attack.origin)
      |> Villa.subtract_supply(result.attacker_supply_loss)
    target_changeset =
      attack.target
      |> Villa.process_virtually_until(attack.arrives_at)
      |> Villa.subtract_resources(result.resources_plundered)
      |> Changeset.put_change(:is_occupied, false)
    origin_of_occupation_changeset =
      Changeset.change(attack.target.occupation.origin)
      |> Villa.subtract_supply(result.defender_supply_loss)

    Multi.new
    |> Multi.append(CombatReport.deliver(combat))
    |> Multi.delete(:attack, attack)
    |> Multi.update(:origin, origin_changeset)
    |> Multi.update(:target, target_changeset)
    |> Multi.update(:origin_of_occupation, origin_of_occupation_changeset)
    |> Multi.delete(:occupation, attack.target.occupation)
    |> append_comeback(combat)
    |> notify_queue
  end
  def to_multi(%Combat{} = combat) do
    %{attack: attack, result: result} = combat

    origin_changeset =
      Changeset.change(attack.origin)
      |> Villa.subtract_supply(result.attacker_supply_loss)
    target_changeset =
      attack.target
      |> Villa.process_virtually_until(attack.arrives_at)
      |> Villa.subtract_units(result.defender_losses)
      |> Villa.subtract_supply(result.defender_supply_loss)
      |> Villa.subtract_resources(result.resources_plundered)

    Multi.new
    |> Multi.append(CombatReport.deliver(combat))
    |> Multi.delete(:attack, attack)
    |> Multi.update(:origin, origin_changeset)
    |> Multi.update(:target, target_changeset)
    |> append_comeback(combat)
    |> notify_queue
  end

  defp notify_queue(multi) do
    multi
    |> Multi.run(:send_to_queue, fn(_repo, changes) ->
      case changes do
        %{comeback: comeback} ->
          LaFamiglia.EventQueue.cast({:new_event, comeback})
        %{occupation: occupation} ->
          LaFamiglia.EventQueue.cast({:new_event, occupation})
        _ -> nil
      end

      {:ok, nil}
    end)
  end

  defp append_comeback(multi, %Combat{result: %{attacker_survived?: true}} = combat) do
    changeset = ComebackMovement.from_combat(combat.attack, combat.result)

    multi
    |> Multi.insert(:comeback, changeset)
  end
  defp append_comeback(multi, _), do: multi
end
