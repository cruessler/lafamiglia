defmodule LaFamiglia.UnitQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  setup do
    villa     = Forge.saved_villa(Repo) |> Repo.preload(:unit_queue_items)
    changeset = Ecto.Changeset.change(villa)
    unit      = Unit.get(1)

    {:ok, %{villa: villa, changeset: changeset, unit: unit}}
  end

  test "should add unit queue item", %{villa: villa, changeset: changeset, unit: unit} do
    assert Unit.number(villa, unit) == 0

    for i <- 1..3 do
      changeset |> UnitQueueItem.enqueue(unit, 10) |> Repo.transaction
      items = Ecto.assoc(villa, :unit_queue_items) |> Repo.all

      assert Enum.count(items) == i
    end

    villa = Repo.get(Villa, villa.id) |> Repo.preload(:unit_queue_items)

    assert Unit.enqueued_number(villa, unit) == 30
  end

  test "should cancel unit queue item", %{villa: villa, changeset: changeset, unit: unit} do
    assert {:ok, _} = UnitQueueItem.enqueue(changeset, unit, 1) |> Repo.transaction

    villa     = Repo.get(Villa, villa.id) |> Repo.preload(:unit_queue_items)
    changeset = Ecto.Changeset.change(villa)

    assert {:ok, _} = UnitQueueItem.dequeue!(changeset, List.last(villa.unit_queue_items))
  end

  test "should recruit in discrete steps", %{villa: villa, changeset: changeset, unit: unit} do
    start_number      = Unit.number(villa, unit)
    number_to_recruit = 10
    total_number      = start_number + number_to_recruit

    {:ok, %{villa: villa}} =
      UnitQueueItem.enqueue(changeset, unit, number_to_recruit)
      |> Repo.transaction

    changeset =
      villa
      # Since `villa.unit_queue_items` is not updated by `UnitQueueItem.enqueue`
      # the association has to be forcefully reloaded.
      |> Repo.preload(:unit_queue_items, force: true)
      |> Ecto.Changeset.change

    for _ <- 1..number_to_recruit do
      changeset = Villa.process_units_virtually_until(changeset, LaFamiglia.DateTime.from_now(Unit.build_time(unit) * 0.9))

      assert total_number == Unit.virtual_number(changeset, unit)
      assert total_number == Unit.number(changeset, unit) + hd(changeset.data.unit_queue_items).number
    end
  end

  test "does not recruit more units than enqueued", %{villa: villa, changeset: changeset, unit: unit} do
    {:ok, %{villa: villa}} =
      changeset
      |> UnitQueueItem.enqueue(unit, 1)
      |> Repo.transaction

    changeset =
      villa
      |> Map.put(:units_recruited_until, LaFamiglia.DateTime.from_now(-86400))
      |> Ecto.Changeset.change
      |> Villa.process_units_virtually_until(LaFamiglia.DateTime.from_now(Unit.build_time(unit) * 0.9))

    assert Unit.number(changeset, unit) == 0
  end

  test "should refund costs", %{villa: villa, changeset: changeset, unit: unit} do
    resources = Villa.get_resources(villa)

    {:ok, %{villa: villa, unit_queue_item: item}} =
      UnitQueueItem.enqueue(changeset, unit, 1)
      |> Repo.transaction

    changeset =
      villa
      # Since `villa.unit_queue_items` is not updated by `UnitQueueItem.enqueue`
      # the association has to be forcefully reloaded.
      |> Repo.preload(:unit_queue_items, force: true)
      |> Ecto.Changeset.change
    {:ok, villa} = UnitQueueItem.dequeue!(changeset, item)

    # It is assumed that the recruitment of the first unit has been started.
    # Thus, no refunds are to be expected.
    assert resources != Villa.get_resources(villa)
  end

  test "should update `units_recruited_until` when event is handled", %{changeset: changeset, unit: unit} do
    {:ok, %{villa: villa, unit_queue_item: first_item}} =
      UnitQueueItem.enqueue(changeset, unit, 5)
      |> Repo.transaction

    {:ok, %{villa: villa}} =
      villa
      |> Ecto.Changeset.change
      |> UnitQueueItem.enqueue(unit, 5)
      |> Repo.transaction

    assert Ecto.Changeset.get_field(changeset, :units_recruited_until) != first_item.completed_at

    LaFamiglia.Event.handle(first_item)

    changeset =
      from(v in Villa, where: v.id == ^villa.id, preload: :unit_queue_items)
      |> Repo.one
      |> Ecto.Changeset.change
      |> Villa.process_virtually_until(first_item.completed_at)

    assert Ecto.Changeset.get_field(changeset, :units_recruited_until) == first_item.completed_at
    assert hd(Ecto.Changeset.get_field(changeset, :unit_queue_items)).number == 5
  end
end
