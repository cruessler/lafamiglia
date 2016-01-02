defmodule LaFamiglia.Combat do
  alias LaFamiglia.Unit

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

    %{"attacker" => attacking_units,
      "defender" => defending_units,
      "winner"   => winner}
  end
end
