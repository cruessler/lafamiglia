defmodule LaFamiglia.EventHandler.AttackTest do
  use LaFamiglia.EventHandlerCase

  alias LaFamiglia.ComebackMovement
  alias LaFamiglia.Occupation
  alias LaFamiglia.Report
  alias LaFamiglia.Resource

  defp report_count do
    from(r in Report, select: count(r.id))
    |> Repo.one
  end

  test "gets handled when attacker wins" do
    attack = insert(:attack)

    old_report_count = report_count
    old_supply       = attack.origin.supply

    assert {:ok, _} = LaFamiglia.Event.handle(attack)

    assert report_count == old_report_count + 2
    assert Repo.get(Villa, attack.origin.id).supply < old_supply

    target = Repo.get(Villa, attack.target.id)
    assert Resource.filter(target) != Resource.filter(attack.target)

    report = from(r in Report, order_by: [desc: :id], limit: 1, preload: :combat_report) |> Repo.one
    assert attack.arrives_at == report.delivered_at

    comeback = from(c in ComebackMovement, preload: :origin) |> Repo.one
    assert comeback.origin.id == attack.origin.id
    assert DateTime.compare(comeback.arrives_at, attack.arrives_at) == :gt
    assert comeback.resource_1 > 0
    assert comeback.resource_1 == report.combat_report.resources_plundered.resource_1
  end

  test "gets handled when attacker loses" do
    attack = insert(:attack, %{unit_1: 1})

    assert {:ok, _} = LaFamiglia.Event.handle(attack)

    assert from(c in ComebackMovement) |> Repo.all |> Enum.count == 0
  end

  test "gets handled when attacker wins and target has no resources" do
    target_without_resources =
      insert(:villa, %{resource_1: 0.0, resource_2: 0.0, resource_3: 0.0})

    attack =
      insert(:attack, %{target: target_without_resources})

    assert {:ok, _} = LaFamiglia.Event.handle(attack)

    comeback = from(c in ComebackMovement, preload: :origin) |> Repo.one
    refute is_nil(comeback.resource_1)
  end

  test "gets handled when attacker begins an occupation" do
    attack = insert(:attack, %{unit_2: 1})

    assert {:ok, _} = LaFamiglia.Event.handle(attack)

    target =
      Repo.get(Villa, attack.target.id)
      |> Repo.preload(:occupation)

    assert target.is_occupied
    assert %Occupation{} = target.occupation
    assert target.occupation.origin_id == attack.origin_id
  end

  test "gets handled when target is occupied" do
    occupation = insert(:occupation)
    attack = insert(:attack, %{target: occupation.target})

    assert {:ok, _} = LaFamiglia.Event.handle(attack)

    target =
      Repo.get(Villa, attack.target.id)
      |> Repo.preload(:occupation)

    assert is_nil(target.occupation)
  end

  test "comeback gets handled" do
    comeback = insert(:comeback)

    assert {:ok, _} = LaFamiglia.Event.handle(comeback)

    origin = Repo.get(Villa, comeback.origin.id)
    assert Resource.filter(origin) != Resource.filter(comeback.origin)
    assert origin.resource_1 == comeback.origin.resource_1 + comeback.resource_1
  end
end
