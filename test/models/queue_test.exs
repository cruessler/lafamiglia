defmodule LaFamiglia.QueueTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Factory
  alias LaFamiglia.Queue

  @shift_by 1_000_000

  test "shift_later_items" do
    [first|[item]] = queue = Factory.building_queue

    [shifted_item] = Queue.shift_later_items(queue, first, @shift_by)

    assert Timex.diff(item.completed_at, shifted_item.completed_at, :seconds) == 1
  end
end
