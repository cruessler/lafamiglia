defmodule LaFamiglia.AttackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.AttackMovement
  alias LaFamiglia.Report

  setup do
    LaFamiglia.DateTime.clock!

    attack =
      Forge.saved_attack_movement(Repo)
      |> Repo.preload([:origin, :target])

    {:ok, %{attack: attack}}
  end

  defp report_count do
    from(r in Report, select: count(r.id))
    |> Repo.one
  end

  test "gets handled", %{attack: attack} do
    old_report_count = report_count

    assert LaFamiglia.Event.handle(attack)

    assert report_count == old_report_count + 2
  end

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
    {:ok, movement} = Repo.insert(changeset)
    assert Ecto.DateTime.compare(movement.arrives_at, LaFamiglia.DateTime.now) == :gt

    changeset = AttackMovement
                  .changeset(%AttackMovement{}, %{movement_params | unit_1: 0})
    refute changeset.valid?

    changeset = AttackMovement
                  .changeset(%AttackMovement{},
                             %{movement_params | target_id: origin.id})
    refute changeset.valid?

    origin_changeset = Ecto.Changeset.change(origin_without_units)
    changeset        = AttackMovement.changeset(%AttackMovement{}, movement_params)

    assert {:error, _} =
      AttackMovement.attack(origin_changeset, changeset)
      |> Repo.update
  end
end
