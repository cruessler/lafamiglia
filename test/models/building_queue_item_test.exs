defmodule LaFamiglia.BuildingQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.BuildingQueueItem

  test "should add building queue item" do
    villa = Forge.saved_villa(Repo)

    for i <- 1..3 do
      villa |> BuildingQueueItem.enqueue(Building.get_by_id(1))
      items = assoc(villa, :building_queue_items) |> Repo.all

      assert Enum.count(items) == i
    end
  end
end
