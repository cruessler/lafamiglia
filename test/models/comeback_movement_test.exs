defmodule LaFamiglia.ComebackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.ComebackMovement

  test "from_attack" do
    attack = build(:attack)

    comeback = ComebackMovement.from_attack(attack)

    assert get_field(comeback, :origin) == attack.origin
    assert Ecto.DateTime.compare(get_field(comeback, :arrives_at), attack.arrives_at) == :gt
  end
end
