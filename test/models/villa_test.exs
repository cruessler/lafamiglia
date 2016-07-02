defmodule LaFamiglia.VillaTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Villa
  alias LaFamiglia.Unit

  @invalid_attrs %{ name: "Ne" }

  test "changeset with valid attributes" do
    changeset = build(:villa) |> change
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Villa.changeset(%Villa{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "should find an empty space for a new villa" do
    assert {_, _} = Villa.empty_coordinates
  end

  test "should create new villas" do
    player = insert(:player)

    villas_count     = assoc(player, :villas) |> Repo.all |> Enum.count
    number_to_create = (Villa.max_x + 1) * (Villa.max_y + 1)

    for _ <- 1..number_to_create do
      Villa.create_for(player) |> Repo.insert!
    end

    assert (villas_count + number_to_create) == assoc(player, :villas) |> Repo.all |> Enum.count
  end

  test "has_resources?" do
    changeset =
      build(:villa, %{resource_1: 10, resource_2: 10, resource_3: 0})
      |> change

    assert Villa.has_resources?(changeset, %{resource_1: 10, resource_2: 10, resource_3: 0})
    refute Villa.has_resources?(changeset, %{resource_1: 10, resource_2: 10, resource_3: 10})
  end

  test "process_units_virtually_until" do
    villa = build(:villa) |> with_unit_queue

    [first, second] = villa.unit_queue_items

    unit   = Unit.get(first.unit_id)
    number = Unit.number(villa, unit)

    changeset =
      villa
      |> change
      |> Villa.process_units_virtually_until(LaFamiglia.DateTime.from_now(first.build_time))

    assert Unit.number(changeset, unit) == number + first.number
    assert Unit.virtual_number(changeset, unit) == number + first.number + second.number
  end

  test "recalc_points" do
    villa = build(:villa)
    old_points = villa.points

    changeset =
      villa
      |> change(%{building_1: villa.building_1 + 1})
      |> Villa.recalc_points

    assert is_integer(get_field(changeset, :points))
    assert get_field(changeset, :points) >= old_points
  end
end
