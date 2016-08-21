defmodule LaFamiglia.ComebackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Unit

  alias LaFamiglia.ComebackMovement

  test "from_attack" do
    attack = build(:attack)

    comeback = ComebackMovement.from_attack(attack)

    assert get_field(comeback, :origin) == attack.origin
    assert Ecto.DateTime.compare(get_field(comeback, :arrives_at), attack.arrives_at) == :gt
  end

  test "from_occupation" do
    occupation = build(:occupation)

    comeback = ComebackMovement.from_occupation(occupation)

    assert get_field(comeback, :origin) == occupation.origin
    assert Ecto.DateTime.compare(get_field(comeback, :arrives_at), occupation.succeeds_at) == :gt
    assert Unit.filter(occupation) == Unit.filter(comeback)
  end
end
