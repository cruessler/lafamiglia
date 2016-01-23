defmodule LaFamiglia.UnitQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  test "should add unit queue item" do
    villa     = Forge.saved_villa(Repo) |> Repo.preload(:unit_queue_items)
    changeset = Ecto.Changeset.change(villa)
    unit      = Unit.get_by_id(1)

    assert Unit.number(villa, unit) == 0

    for i <- 1..3 do
      changeset |> UnitQueueItem.enqueue!(unit, 10)
      items = assoc(villa, :unit_queue_items) |> Repo.all

      assert Enum.count(items) == i
    end

    villa = Repo.get(Villa, villa.id) |> Repo.preload(:unit_queue_items)

    assert Unit.enqueued_number(villa, unit) == 30
  end

  test "should cancel unit queue item" do
    villa     = Forge.saved_villa(Repo) |> Repo.preload(:unit_queue_items)
    changeset = Ecto.Changeset.change(villa)
    unit      = Unit.get_by_id(1)

    assert {:ok, _item} = UnitQueueItem.enqueue!(changeset, unit, 1)

    villa     = Repo.get(Villa, villa.id) |> Repo.preload(:unit_queue_items)
    changeset = Ecto.Changeset.change(villa)

    assert {:ok, _} = UnitQueueItem.dequeue!(changeset, List.last(villa.unit_queue_items))
  end

  test "should recruit in discrete steps" do
    villa     = Forge.saved_villa(Repo) |> Repo.preload(:unit_queue_items)
    changeset = Ecto.Changeset.change(villa)
    unit      = Unit.get_by_id(1)

    start_number      = Unit.number(villa, unit)
    number_to_recruit = 10
    total_number      = start_number + number_to_recruit

    {:ok, villa} = UnitQueueItem.enqueue!(changeset, unit, number_to_recruit)

    changeset = Ecto.Changeset.change(villa)

    for _ <- 1..number_to_recruit do
      changeset = Villa.process_units_virtually_until(changeset, LaFamiglia.DateTime.add_seconds(LaFamiglia.DateTime.now, Unit.build_time(unit) * 0.9))

      assert total_number == Unit.virtual_number(changeset, unit)
      assert total_number == Unit.number(changeset, unit) + hd(changeset.model.unit_queue_items).number
    end
  end

  test "should refund costs" do
    villa     = Forge.saved_villa(Repo) |> Repo.preload(:unit_queue_items)
    changeset = Ecto.Changeset.change(villa)
    unit      = Unit.get_by_id(1)
    resources = Villa.get_resources(villa)

    {:ok, villa} = UnitQueueItem.enqueue!(changeset, unit, 1)

    changeset = Ecto.Changeset.change(villa)
    {:ok, villa} = UnitQueueItem.dequeue!(changeset, List.last(villa.unit_queue_items))

    # It is assumed that the recruitment of the first unit has been started.
    # Thus, no refunds are to be expected.
    assert resources != Villa.get_resources(villa)
  end
end
