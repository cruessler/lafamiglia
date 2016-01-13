defmodule LaFamiglia.Combat do
  alias LaFamiglia.Unit
  alias LaFamiglia.ReportData

  def calculate(attacker, defender) do
    attacking_units = Unit.filter(attacker)
    defending_units = Unit.filter(defender)

    attack_value = Enum.reduce Unit.all, 0, fn({k, u}, acc) ->
      acc + Map.get(attacking_units, k) * u.attack
    end
    defense_value = Enum.reduce Unit.all, 0, fn({k, u}, acc) ->
      acc + Map.get(defending_units, k) * u.defense
    end
    defense_value = Enum.reduce Building.all, defense_value, fn({k, b}, acc) ->
      acc + b.defense.(Map.get(defender, k))
    end

    winner = if attack_value > defense_value, do: :attacker, else: :defender

    case winner do
      :attacker ->
        attacker_percent_loss = :math.pow(defense_value / attack_value, 1.5)
        defender_percent_loss = 1
      :defender ->
        attacker_percent_loss = 1
        defender_percent_loss = :math.pow(attack_value / defense_value, 1.5)
    end

    attacker_losses =
      Enum.map(Unit.all, fn({k, u}) ->
        {k, round(Map.get(attacker, k) * attacker_percent_loss)}
      end)
      |> Enum.into(%{})
    defender_losses =
      Enum.map(Unit.all, fn({k, u}) ->
        {k, round(Map.get(defender, k) * defender_percent_loss)}
      end)
      |> Enum.into(%{})

    attacker_supply_loss = Unit.supply(attacker_losses)
    defender_supply_loss = Unit.supply(defender_losses)

    attacker_after_combat =
      Map.merge attacking_units, attacker_losses, fn(k, v1, v2) ->
        v1 - v2
      end
    defender_after_combat =
      Map.merge defending_units, defender_losses, fn(k, v1, v2) ->
        v1 - v2
      end

    %ReportData{attacker: attacking_units,
                attacker_losses: attacker_losses,
                attacker_after_combat: attacker_after_combat,
                attacker_supply_loss: attacker_supply_loss,
                defender: defending_units,
                defender_losses: defender_losses,
                defender_after_combat: defender_after_combat,
                defender_supply_loss: defender_supply_loss,
                winner: winner}
  end
end
