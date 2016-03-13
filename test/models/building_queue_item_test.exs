defmodule LaFamiglia.BuildingQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Building

  alias LaFamiglia.BuildingQueueItem

  setup do
    villa     = Forge.saved_villa(Repo) |> Repo.preload(:building_queue_items)
    changeset = Ecto.Changeset.change(villa)
    building  = Building.get(1)

    {:ok, %{villa: villa, changeset: changeset, building: building}}
  end

  test "should add building queue item", %{villa: villa, changeset: changeset, building: building} do
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

  test "should cancel building queue item", %{villa: villa, changeset: changeset, building: building} do
    assert {:ok, _} = BuildingQueueItem.enqueue!(changeset, building)

    villa     = Repo.get(Villa, villa.id) |> Repo.preload(:building_queue_items)
    changeset = Ecto.Changeset.change(villa)

    assert {:ok, _} = BuildingQueueItem.dequeue!(changeset, List.last(villa.building_queue_items))
  end

  test "should respect validations", %{changeset: changeset, building: building} do
    assert {:error, _} =
      changeset
      |> Villa.changeset(%{resource_1: 0})
      |> BuildingQueueItem.enqueue!(building)

    assert {:error, _} =
      changeset
      |> Villa.changeset(%{building_1: building.maxlevel})
      |> BuildingQueueItem.enqueue!(building)
  end
end
