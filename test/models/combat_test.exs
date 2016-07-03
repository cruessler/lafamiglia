defmodule LaFamiglia.CombatTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Combat
  alias LaFamiglia.{Resource, Unit}

  setup do
    LaFamiglia.DateTime.clock!

    attack = build(:attack)

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
    assert Resource.filter(result.defender) == result.resources_plundered
    refute result.results_in_occupation?
  end

  test "results in occupation" do
    attack = build(:attack, %{unit_1: 1000, unit_2: 2})

    result = Combat.calculate(attack, attack.target)

    assert result.results_in_occupation?
  end

  test "has supply loss", %{result: result} do
    assert result.attacker_supply_loss > 0
    assert result.defender_supply_loss == 0
  end
end
