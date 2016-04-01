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
      changeset
      |> BuildingQueueItem.enqueue(building)
      |> Repo.transaction

      items = Ecto.assoc(villa, :building_queue_items) |> Repo.all

      assert Enum.count(items) == i
    end

    villa     = Repo.get(Villa, villa.id) |> Repo.preload(:building_queue_items)
    changeset = Ecto.Changeset.change(villa)

    assert Building.virtual_level(changeset, building) == 4
  end

  test "should cancel building queue item", %{villa: villa, changeset: changeset, building: building} do
    assert {:ok, _} =
      changeset
      |> BuildingQueueItem.enqueue(building)
      |> Repo.transaction

    villa     = Repo.get(Villa, villa.id) |> Repo.preload(:building_queue_items)
    changeset = Ecto.Changeset.change(villa)

    assert {:ok, _} =
      changeset
      |> BuildingQueueItem.dequeue(List.last(villa.building_queue_items))
      |> Repo.transaction
  end

  test "should respect validations", %{changeset: changeset, building: building} do
    assert {:error, :villa, _, _} =
      changeset
      |> Villa.changeset(%{resource_1: 0})
      |> BuildingQueueItem.enqueue(building)
      |> Repo.transaction

    assert {:error, :villa, _, _} =
      changeset
      |> Villa.changeset(%{building_1: building.maxlevel})
      |> BuildingQueueItem.enqueue(building)
      |> Repo.transaction
  end

  test "should update `resources_gained_until` when event is handled", %{changeset: changeset, building: building} do
    {:ok, %{villa: villa}} =
      changeset
      |> BuildingQueueItem.enqueue(building)
      |> Repo.transaction

    {:ok, %{villa: villa}} =
      villa
      |> Ecto.Changeset.change
      |> BuildingQueueItem.enqueue(building)
      |> Repo.transaction

    [first_item|_] = villa.building_queue_items

    assert Ecto.Changeset.get_field(changeset, :resources_gained_until) != first_item.completed_at

    LaFamiglia.Event.handle(first_item)

    changeset =
      from(v in Villa,
           where: v.id == ^villa.id,
           preload: [:building_queue_items, :unit_queue_items])
      |> Repo.one
      |> Ecto.Changeset.change
      |> Villa.process_virtually_until(first_item.completed_at)

    assert Ecto.Changeset.get_field(changeset, :resources_gained_until) == first_item.completed_at
  end
end
