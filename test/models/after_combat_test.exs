defmodule LaFamiglia.AfterCombatTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Combat.AfterCombat

  test "plunder" do
    assert AfterCombat.plunder(%{resource_1: 100, resource_2: 50, resource_3: 0}, 50) ==
      %{resource_1: 25, resource_2: 25, resource_3: 0}
    assert AfterCombat.plunder(%{resource_1: 1000, resource_2: 50, resource_3: 0}, 500) ==
      %{resource_1: 450, resource_2: 50, resource_3: 0}
    assert AfterCombat.plunder(%{resource_1: 1000, resource_2: 1000, resource_3: 500}, 750) ==
      %{resource_1: 250, resource_2: 250, resource_3: 250}
  end
end
