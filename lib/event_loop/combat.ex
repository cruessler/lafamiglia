defmodule LaFamiglia.Combat do
  alias LaFamiglia.{Building, Resource, Unit}
  alias LaFamiglia.CombatResult
  alias LaFamiglia.Combat.AfterCombat

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
      |> calculate_plundered_resources
  end

  defp calculate_combat_values(result) do
    attack_value = Enum.reduce Unit.all, 0, fn({k, u}, acc) ->
      acc + Map.get(result.attacker_before_combat, k) * u.attack
    end
    defense_value = Enum.reduce Unit.all, 0, fn({k, u}, acc) ->
      acc + Map.get(result.defender_before_combat, k) * u.defense
    end
    defense_value = Enum.reduce Building.all, defense_value, fn({k, b}, acc) ->
      acc + b.defense.(Map.get(result.defender, k))
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
