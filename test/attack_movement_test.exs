defmodule LaFamiglia.AttackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.AttackMovement

  test "can be canceled" do
    attack = build(:attack)

    changeset = AttackMovement.cancel(attack)

    assert get_field(changeset, :origin) == attack.origin
    assert get_field(changeset, :unit_1) == attack.unit_1
    assert DateTime.compare(get_field(changeset, :arrives_at), attack.arrives_at) == :gt
  end

  test "arrives_at is in the future" do
    target = build(:villa)

    arrives_at =
      build(:villa, %{unit_1: 1})
      |> change
      |> AttackMovement.create(target, %{unit_1: 1, unit_2: 0})
      |> get_change(:arrives_at)

    assert DateTime.compare(arrives_at, LaFamiglia.DateTime.now()) == :gt
  end

  test "is invalid without units" do
    target = build(:villa)

    changeset =
      build(:villa)
      |> change
      |> AttackMovement.create(target, %{unit_1: 0, unit_2: 0})

    refute changeset.valid?
  end

  test "is invalid when origin == target" do
    origin = build(:villa)

    changeset =
      change(origin)
      |> AttackMovement.create(origin, %{unit_1: 1, unit_2: 0})

    refute changeset.valid?
  end

  test "is invalid when origin does not have units" do
    target = build(:villa)

    changeset =
      build(:villa, %{unit_1: 0})
      |> change
      |> AttackMovement.create(target, %{unit_1: 1, unit_2: 0})

    refute changeset.valid?
  end
end
