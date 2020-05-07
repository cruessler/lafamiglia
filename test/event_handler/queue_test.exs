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
end
