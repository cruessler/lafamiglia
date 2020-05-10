defmodule LaFamiglia.EventHandler.QueueTest do
  use LaFamiglia.EventHandlerCase

  test "should update `resources_gained_until` when build event is handled" do
    villa = build(:villa) |> with_building_queue |> Repo.insert!()
    changeset = change(villa)

    [first | _] = villa.building_queue_items

    assert get_field(changeset, :resources_gained_until) != first.completed_at

    assert {:ok, _} = LaFamiglia.Event.handle(first)

    changeset =
      Repo.get(Villa, villa.id)
      |> Repo.preload([:building_queue_items, :unit_queue_items])
      |> change
      |> Villa.process_virtually_until(first.completed_at)

    assert DateTime.compare(get_field(changeset, :resources_gained_until), first.completed_at) ==
             :eq
  end

  test "should update `units_recruited_until` when recruit event is handled" do
    villa = build(:villa) |> with_unit_queue |> Repo.insert!()
    changeset = villa |> change

    [first | _] = villa.unit_queue_items

    assert get_field(changeset, :units_recruited_until) != first.completed_at

    assert {:ok, _} = LaFamiglia.Event.handle(first)

    changeset =
      Repo.get(Villa, villa.id)
      |> Repo.preload(:unit_queue_items)
      |> change
      |> Villa.process_virtually_until(first.completed_at)

    assert get_field(changeset, :units_recruited_until) == first.completed_at
    assert hd(get_field(changeset, :unit_queue_items)).number == 10
  end

  test "should handle events" do
    villa = build(:villa) |> with_unit_queue

    event_in_the_past = %TestEvent{
      id: 1,
      happens_at: LaFamiglia.DateTime.from_now(milliseconds: 100),
      pid: self()
    }

    event = %TestEvent{id: 2, happens_at: LaFamiglia.DateTime.now(), pid: self()}

    event_in_the_future = %TestEvent{
      id: 3,
      happens_at: LaFamiglia.DateTime.from_now(milliseconds: 1000),
      pid: self()
    }

    events = %{1 => event_in_the_past, 2 => event, 3 => event_in_the_future}

    defmodule TestStore do
      @events events

      def load(), do: []

      def get!(_module, id), do: @events[id]
    end

    {:ok, _} = EventQueue.start_link(store: TestStore)

    EventQueue.cast({:new_event, event_in_the_past})

    assert_receive {:handle, 1}

    EventQueue.cast({:new_event, event})

    assert_receive {:handle, 2}

    EventQueue.cast({:new_event, event_in_the_future})

    refute_receive {:handle, 3}, 50
  end
end
