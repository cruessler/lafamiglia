defmodule LaFamiglia.BuildingQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Building
  alias LaFamiglia.BuildingQueueItem

  setup do
    {:ok, %{building: Building.get(1)}}
  end

  test "should add building queue item", %{building: building} do
    villa = build(:villa)

    assert Building.virtual_level(villa, building) == 1

    changeset = change(villa) |> BuildingQueueItem.enqueue(building)

    assert Building.virtual_level(changeset, building) == 2

    changeset = BuildingQueueItem.enqueue(changeset, building)

    assert Building.virtual_level(changeset, building) == 3
  end

  test "should cancel building queue item" do
    villa = build(:villa) |> with_building_queue |> Repo.insert!()

    assert {:ok, new_villa} =
             change(villa)
             |> BuildingQueueItem.dequeue(List.last(villa.building_queue_items))
             |> Repo.update()

    assert length(new_villa.building_queue_items) == length(villa.building_queue_items) - 1
  end

  test "should respect validations", %{building: building} do
    villa = build(:villa)

    changeset =
      villa
      |> Villa.changeset(%{resource_1: 0})
      |> BuildingQueueItem.enqueue(building)

    refute changeset.valid?

    changeset =
      villa
      |> Villa.changeset(%{building_1: building.maxlevel})
      |> BuildingQueueItem.enqueue(building)

    refute changeset.valid?
  end
end
