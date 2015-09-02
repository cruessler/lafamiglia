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

    assert Unit.enqueued_number(villa, unit) == 30
  end
end
