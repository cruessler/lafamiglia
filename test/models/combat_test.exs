defmodule LaFamiglia.CombatTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Repo

  alias LaFamiglia.Combat
  alias LaFamiglia.Unit

  setup do
    LaFamiglia.DateTime.clock!

    attack =
      Forge.saved_attack_movement(Repo)
      |> Repo.preload([:origin, :target])

    {:ok, %{result: Combat.calculate(attack, attack.target)}}
  end

  test "has combat values", %{result: result} do
    assert result.attack_value > result.defense_value
    assert result.defense_value > 0
  end

  test "has a winner", %{result: result} do
    assert result.winner == :attacker
  end

  test "has losses", %{result: result} do
    assert result.attacker_percent_loss != 1
    assert result.defender_percent_loss == 1

    assert Unit.supply(result.attacker_after_combat) > 0
    assert Unit.supply(result.defender_after_combat) == 0

    assert result.attacker_survived?
  end

  test "has supply loss", %{result: result} do
    assert result.attacker_supply_loss > 0
    assert result.defender_supply_loss == 0
  end
end
