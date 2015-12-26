defmodule LaFamiglia.Combat do
  alias LaFamiglia.Unit

  def calculate(attacker, defender) do
    %{"attacker" => Unit.filter(attacker),
      "defender" => Unit.filter(defender),
      "winner"   => "defender"}
  end
end
