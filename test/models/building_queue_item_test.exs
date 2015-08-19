defmodule LaFamiglia.BuildingQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.BuildingQueueItem

  test "should add building queue item" do
    villa    = Forge.saved_villa(Repo)
    building = Building.get_by_id(1)

    assert Building.virtual_level(villa, building) == 1

    for i <- 1..3 do
      villa |> BuildingQueueItem.enqueue(building)
      items = assoc(villa, :building_queue_items) |> Repo.all

      assert Enum.count(items) == i
    end

    assert Building.virtual_level(villa, building) == 4
  end
end
