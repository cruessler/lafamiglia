defmodule LaFamiglia.AttackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement
  alias LaFamiglia.Occupation
  alias LaFamiglia.Report
  alias LaFamiglia.Resource

  setup do
    LaFamiglia.DateTime.clock!

    :ok
  end

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

    report = from(r in Report, order_by: [desc: :id], limit: 1) |> Repo.one
    assert attack.arrives_at == report.delivered_at

    comeback = from(c in ComebackMovement, preload: :origin) |> Repo.one
    assert comeback.origin.id == attack.origin.id
    assert Ecto.DateTime.compare(comeback.arrives_at, attack.arrives_at) == :gt
    assert comeback.resource_1 > 0
    assert comeback.resource_1 == report.data.resources_plundered.resource_1
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

  test "can be canceled" do
    attack = build(:attack)

    changeset = AttackMovement.cancel(attack)

    assert get_field(changeset, :origin) == attack.origin
    assert get_field(changeset, :unit_1) == attack.unit_1
    assert Ecto.DateTime.compare(get_field(changeset, :arrives_at), attack.arrives_at) == :gt
  end

  test "arrives_at is in the future" do
    target = build(:villa)

    arrives_at =
      build(:villa, %{unit_1: 1})
      |> change
      |> AttackMovement.create(target, %{unit_1: 1, unit_2: 0})
      |> get_change(:arrives_at)

    assert Ecto.DateTime.compare(arrives_at, LaFamiglia.DateTime.now) == :gt
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
