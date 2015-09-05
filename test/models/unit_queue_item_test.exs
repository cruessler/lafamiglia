defmodule LaFamiglia.UnitQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  test "should add unit queue item" do
    villa = Forge.saved_villa(Repo)
    unit  = Unit.get_by_id(1)

    assert Unit.number(villa, unit) == 0

    for i <- 1..3 do
      villa |> UnitQueueItem.enqueue!(unit, 10)
      items = assoc(villa, :unit_queue_items) |> Repo.all

      assert Enum.count(items) == i
    end

    villa = Repo.preload(villa, :unit_queue_items)

    assert Unit.enqueued_number(villa, unit) == 30
  end

  test "should cancel unit queue item" do
    villa = Forge.saved_villa(Repo)
    unit  = Unit.get_by_id(1)

    assert {:ok, _item} = UnitQueueItem.enqueue!(villa, unit, 1)

    villa = Repo.get(Villa, villa.id) |> Repo.preload(:unit_queue_items)

    assert {:ok, _} = UnitQueueItem.dequeue!(villa, List.last(villa.unit_queue_items))
  end

  test "should recruit in discrete steps" do
    villa = Forge.saved_villa(Repo)
    unit  = Unit.get_by_id(1)

    start_number      = Unit.number(villa, unit)
    number_to_recruit = 50
    total_number      = start_number + number_to_recruit

    UnitQueueItem.enqueue!(villa, unit, number_to_recruit)

    villa = Repo.get(Villa, villa.id)

    for _ <- 1..number_to_recruit do
      villa = Villa.process_units_virtually_until(villa, LaFamiglia.DateTime.add_seconds(LaFamiglia.DateTime.now, unit.build_time * 0.9))

      assert total_number == Unit.virtual_number(villa, unit)
      assert total_number == Unit.number(villa, unit) + hd(villa.unit_queue_items).number
    end
  end
end
