defmodule LaFamiglia.AttackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.AttackMovement

  test "should respect validations" do
    origin_without_units = Forge.saved_villa(Repo)
    origin = Forge.saved_villa(Repo, unit_1: 10)
    target = Forge.saved_villa(Repo)

    movement_params = %{origin_id: origin.id,
                        target_id: target.id,
                        unit_1: 1,
                        unit_2: 0}

    changeset = AttackMovement
                  .changeset(%AttackMovement{}, movement_params)
    assert changeset.valid?

    changeset = AttackMovement
                  .changeset(%AttackMovement{}, %{movement_params | unit_1: 0})
    refute changeset.valid?

    changeset = AttackMovement
                  .changeset(%AttackMovement{},
                             %{movement_params | origin_id: origin_without_units.id})
    refute changeset.valid?

    changeset = AttackMovement
                  .changeset(%AttackMovement{},
                             %{movement_params | target_id: origin.id})
    refute changeset.valid?
  end
end
