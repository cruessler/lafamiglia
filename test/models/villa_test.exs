defmodule LaFamiglia.VillaTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Villa

  @valid_attrs %{ name: "New villa", x: 0, y: 0, player_id: 1,
                  resource_1: 0, resource_2: 0, resource_3: 0,
                  building_1: 1, building_2: 0,
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
end
