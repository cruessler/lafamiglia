defmodule LaFamiglia.BuildingQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Building

  alias LaFamiglia.BuildingQueueItem

  test "should add building queue item" do
    villa     = Forge.saved_villa(Repo) |> Repo.preload(:building_queue_items)
    changeset = Ecto.Changeset.change(villa)
    building  = Building.get_by_id(1)

    assert Building.virtual_level(villa, building) == 1

    for i <- 1..3 do
      changeset |> BuildingQueueItem.enqueue!(building)
      items = assoc(villa, :building_queue_items) |> Repo.all

      assert Enum.count(items) == i
    end

    villa     = Repo.get(Villa, villa.id) |> Repo.preload(:building_queue_items)
    changeset = Ecto.Changeset.change(villa)

    assert Building.virtual_level(changeset, building) == 4
  end

  test "should cancel building queue item" do
    villa     = Forge.saved_villa(Repo)
    changeset = Ecto.Changeset.change(villa)
    building  = Building.get_by_id(1)

    assert {:ok, _} = BuildingQueueItem.enqueue!(changeset, building)

    villa     = Repo.get(Villa, villa.id) |> Repo.preload(:building_queue_items)
    changeset = Ecto.Changeset.change(villa)

    assert {:ok, _} = BuildingQueueItem.dequeue!(changeset, List.last(villa.building_queue_items))
  end

  test "should respect validations" do
    villa     = Forge.saved_villa(Repo)
    changeset = Villa.changeset(villa, %{resource_1: 0})
    building  = Building.get_by_id(1)

    assert {:error, _} = changeset |> BuildingQueueItem.enqueue!(building)

    building = %{building | maxlevel: 1}

    assert {:error, _} = changeset |> BuildingQueueItem.enqueue!(building)
  end
end
