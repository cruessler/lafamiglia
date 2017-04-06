defmodule LaFamiglia.QueueTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Factory
  alias LaFamiglia.Queue

  @shift_by 1

  test "shift_later_items" do
    [first|[item]] = queue = Factory.building_queue

    [shifted_item] = Queue.shift_later_items(queue, first, @shift_by * 1_000_000)

    assert shifted_item.completed_at.second == item.completed_at.second - 1
  end
end
