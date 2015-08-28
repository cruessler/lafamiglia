defmodule LaFamiglia.BuildingQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.BuildingQueueItem

  test "should add building queue item" do
    villa    = Forge.saved_villa(Repo)
    building = Building.get_by_id(1)

    assert Building.virtual_level(villa, building) == 1

    for i <- 1..3 do
      villa |> BuildingQueueItem.enqueue!(building)
      items = assoc(villa, :building_queue_items) |> Repo.all

      assert Enum.count(items) == i
    end

    assert Building.virtual_level(villa, building) == 4
  end

  test "should cancel building queue item" do
    villa    = Forge.saved_villa(Repo)
    building = Building.get_by_id(1)

    assert {:ok, villa} = BuildingQueueItem.enqueue!(villa, building)
    assert {:ok, _}     = BuildingQueueItem.dequeue!(villa, List.last(villa.building_queue_items))
  end

  test "should respect validations" do
    villa    = %Villa{Forge.saved_villa(Repo) | resource_1: 0 }
    building = Building.get_by_id(1)

    assert {:error, _changeset} = villa |> BuildingQueueItem.enqueue!(building)

    building = %{building | maxlevel: 1}

    assert {:error, _changeset} = villa |> BuildingQueueItem.enqueue!(building)
  end

  test "should update processed_until" do
    building = Building.get_by_id(1)

    {:ok, villa} =
      Forge.saved_villa(Repo)
      |> Map.put(:processed_until, LaFamiglia.DateTime.add_seconds(LaFamiglia.DateTime.now, -86400))
      |> BuildingQueueItem.enqueue!(building)

    assert villa.processed_until == LaFamiglia.DateTime.now
  end
end
