defmodule LaFamiglia.VillaTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Villa
  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  @valid_attrs %{ name: "New villa", x: 0, y: 0, player_id: 1,
                  resource_1: 0, resource_2: 0, resource_3: 0,
                  building_1: 1, building_2: 0,
                  building_3: 0, building_4: 0, building_5: 0,
                  unit_1: 0, unit_2: 0,
                  supply: 0, max_supply: 100,
                  storage_capacity: 100 }
  @invalid_attrs %{ name: "Ne" }

  test "changeset with valid attributes" do
    attrs =
      @valid_attrs
      |> Map.put(:resources_gained_until, LaFamiglia.DateTime.now)
      |> Map.put(:units_recruited_until, LaFamiglia.DateTime.now)

    changeset = Villa.changeset(%Villa{}, attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Villa.changeset(%Villa{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "should find an empty space for a new villa" do
    refute is_nil(Villa.empty_coordinates)
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
    villa     = Forge.villa(resource_1: 10, resource_2: 10, resource_3: 0)
    changeset = Ecto.Changeset.change(villa)

    assert Villa.has_resources?(changeset, %{resource_1: 10, resource_2: 10, resource_3: 0})
    refute Villa.has_resources?(changeset, %{resource_1: 10, resource_2: 10, resource_3: 10})
  end

  test "process_units_virtually_until" do
    villa     = Forge.saved_villa(Repo) |> Repo.preload(:unit_queue_items)
    changeset = Ecto.Changeset.change(villa)
    unit   = Unit.get(1)
    number = Map.get(villa, unit.key)

    {:ok, villa} = UnitQueueItem.enqueue!(changeset, unit, 10)

    changeset = Ecto.Changeset.change(villa)

    changeset = Villa.process_units_virtually_until(changeset, LaFamiglia.DateTime.from_now(Unit.build_time(unit) + 1))

    assert Unit.number(changeset, unit) == number + 1
    assert Unit.virtual_number(changeset, unit) == number + 10
  end

  test "recalc_points" do
    villa      = Forge.saved_villa(Repo)
    old_points = villa.points
    changeset  = Ecto.Changeset.change(villa, %{building_1: villa.building_1 + 1})

    changeset = Villa.recalc_points(changeset)
    refute is_nil(Ecto.Changeset.get_field(changeset, :points))
    assert Ecto.Changeset.get_field(changeset, :points) != old_points
  end
end
