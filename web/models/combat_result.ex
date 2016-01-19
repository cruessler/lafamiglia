defmodule LaFamiglia.CombatResult do
  defstruct [:attacker, :attacker_losses,
             :attacker_after_combat, :attacker_supply_loss,
             :defender, :defender_losses,
             :defender_after_combat, :defender_supply_loss,
             :winner, :attacker_survived?]
end
