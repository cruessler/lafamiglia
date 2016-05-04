defmodule LaFamiglia.AttackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement
  alias LaFamiglia.Report
  alias LaFamiglia.Resource

  setup do
    LaFamiglia.DateTime.clock!

    attack =
      Forge.saved_attack_movement(Repo)
      |> Repo.preload(origin: :player, target: :player)

    origin = Forge.saved_villa(Repo, unit_1: 10)
    target = Forge.saved_villa(Repo)
    origin_changeset = Ecto.Changeset.change(origin)

    movement_params = %{unit_1: 1, unit_2: 0}

    {:ok, %{attack: attack,
            origin: origin, target: target,
            origin_changeset: origin_changeset,
            movement_params: movement_params}}
  end

  defp report_count do
    from(r in Report, select: count(r.id))
    |> Repo.one
  end

  test "gets handled", %{attack: attack} = context do
    old_report_count = report_count
    old_supply       = attack.origin.supply

    assert LaFamiglia.Event.handle(attack)

    assert report_count == old_report_count + 2
    assert Repo.get(Villa, attack.origin.id).supply < old_supply

    target = Repo.get(Villa, attack.target.id)
    assert Resource.filter(target) != Resource.filter(attack.target)

    report = from(r in Report, order_by: [desc: :id], limit: 1) |> Repo.one
    assert attack.arrives_at == report.delivered_at

    comeback = from(c in ComebackMovement, preload: :origin) |> Repo.one
    assert comeback.origin.id == attack.origin.id
    assert Ecto.DateTime.compare(comeback.arrives_at, attack.arrives_at) == :gt
    assert comeback.resource_1 > 0
    assert comeback.resource_1 == report.data.resources_plundered.resource_1
  end

  test "can be canceled", %{attack: attack} do
    {:ok, %{comeback: comeback}} = AttackMovement.cancel(attack) |> Repo.transaction

    assert comeback.origin.id == attack.origin.id
    assert comeback.unit_1 == attack.unit_1
    assert Ecto.DateTime.compare(comeback.arrives_at, attack.arrives_at) == :gt
  end

  test "arrives_at is in the future", context do
    {:ok, movement} =
      AttackMovement.create(context.origin_changeset,
                            context.target,
                            context.movement_params)
      |> Repo.insert

    assert Ecto.DateTime.compare(movement.arrives_at, LaFamiglia.DateTime.now) == :gt
  end

  test "is invalid without units", context do
    changeset =
      AttackMovement.create(context.origin_changeset,
                            context.target,
                            %{context.movement_params | unit_1: 0})

    refute changeset.valid?
  end

  test "is invalid when origin == target", context do
    changeset =
      AttackMovement.create(context.origin_changeset,
                            context.origin,
                            context.movement_params)

    refute changeset.valid?
  end

  test "is invalid when origin does not have units", context do
    origin           = Forge.saved_villa(Repo)
    origin_changeset = Ecto.Changeset.change(origin)

    assert {:error, _} =
      AttackMovement.create(origin_changeset, context.target, context.movement_params)
      |> Repo.update
  end
end
