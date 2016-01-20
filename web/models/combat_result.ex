defmodule LaFamiglia.CombatResult do
  defstruct [
    :attacker,
    :attacker_before_combat, :attack_value,
    :attacker_percent_loss, :attacker_losses,
    :attacker_after_combat, :attacker_supply_loss,
    :defender,
    :defender_before_combat, :defender_buildings, :defense_value,
    :defender_percent_loss, :defender_losses,
    :defender_after_combat, :defender_supply_loss,
    :winner, :attacker_survived?
  ]
end
