defmodule LaFamiglia.VillaTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Villa
  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  @valid_attrs %{ name: "New villa", x: 0, y: 0, player_id: 1,
                  resource_1: 0, resource_2: 0, resource_3: 0,
                  building_1: 1, building_2: 0,
                  unit_1: 0, unit_2: 0,
                  supply: 0, max_supply: 100,
                  storage_capacity: 100 }
  @invalid_attrs %{ name: "Ne" }

  test "changeset with valid attributes" do
    changeset = Villa.changeset(%Villa{}, Map.put(@valid_attrs, :processed_until, LaFamiglia.DateTime.now))
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Villa.changeset(%Villa{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "should find an empty space for a new villa" do
    assert Villa.empty_coordinates != nil
  end

  test "should create new villas" do
    player = Forge.saved_player(Repo)

    villas_count     = assoc(player, :villas) |> Repo.all |> Enum.count
    number_to_create = 121

    :random.seed(:erlang.monotonic_time)

    for _ <- 1..number_to_create do
      Villa.create_for(player)
    end

    assert (villas_count + number_to_create) == assoc(player, :villas) |> Repo.all |> Enum.count
  end

  test "has_resources?" do
    villa = Forge.villa(resource_1: 10, resource_2: 10, resource_3: 0)

    assert Villa.has_resources?(villa, %{resource_1: 10, resource_2: 10, resource_3: 0})
    refute Villa.has_resources?(villa, %{resource_1: 10, resource_2: 10, resource_3: 10})
  end

  test "process_units_virtually_until" do
    villa  = Forge.saved_villa(Repo)
    unit   = Unit.get_by_id(1)
    number = Map.get(villa, unit.key)

    UnitQueueItem.enqueue!(villa, unit, 10)

    villa = Repo.get(Villa, villa.id)

    villa = Villa.process_units_virtually_until(villa, LaFamiglia.DateTime.add_seconds(LaFamiglia.DateTime.now, unit.build_time + 1))

    assert Unit.number(villa, unit) == number + 1
    assert Unit.virtual_number(villa, unit) == number + 10
  end
end
