defmodule LaFamiglia.AttackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.AttackMovement
  alias LaFamiglia.Report

  setup do
    LaFamiglia.DateTime.clock!

    attack =
      Forge.saved_attack_movement(Repo)
      |> Repo.preload(origin: :player, target: :player)

    movement_params =
      %{origin_id: Forge.saved_villa(Repo, unit_1: 10).id,
        target_id: Forge.saved_villa(Repo).id,
        unit_1: 1,
        unit_2: 0}

    {:ok, %{attack: attack, movement_params: movement_params}}
  end

  defp report_count do
    from(r in Report, select: count(r.id))
    |> Repo.one
  end

  test "gets handled", %{attack: attack} do
    old_report_count = report_count
    old_supply       = attack.origin.supply

    assert LaFamiglia.Event.handle(attack)

    assert report_count == old_report_count + 2
    assert Repo.get(Villa, attack.origin.id).supply < old_supply
  end

  test "arrives_at is in the future", %{movement_params: params} do
    {:ok, movement} =
      %AttackMovement{}
      |> AttackMovement.changeset(params)
      |> Repo.insert

    assert Ecto.DateTime.compare(movement.arrives_at, LaFamiglia.DateTime.now) == :gt
  end

  test "is invalid without units", %{movement_params: params} do
    changeset =
      %AttackMovement{}
      |> AttackMovement.changeset(%{params | unit_1: 0})

    refute changeset.valid?
  end

  test "is invalid when origin == target", %{movement_params: params} do
    changeset =
      %AttackMovement{}
      |> AttackMovement.changeset(%{params | target_id: params.origin_id})

    refute changeset.valid?
  end

  test "is invalide when origin does not have units", %{movement_params: params} do
    origin           = Forge.saved_villa(Repo)
    origin_changeset = Ecto.Changeset.change(origin)

    changeset =
      %AttackMovement{}
      |> AttackMovement.changeset(%{params | origin_id: origin.id})

    assert {:error, _} =
      AttackMovement.attack(origin_changeset, changeset)
      |> Repo.update
  end
end
