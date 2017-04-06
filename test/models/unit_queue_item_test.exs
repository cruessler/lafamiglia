defmodule LaFamiglia.UnitQueueItemTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.{Resource, Unit}
  alias LaFamiglia.UnitQueueItem

  setup do
    {:ok, %{unit: Unit.get(1)}}
  end

  test "should add unit queue item", %{unit: unit} do
    villa = build(:villa)

    assert Unit.enqueued_number(villa, unit) == 0

    changeset = change(villa) |> UnitQueueItem.enqueue(unit, 10)

    assert Unit.enqueued_number(changeset, unit) == 10

    changeset = UnitQueueItem.enqueue(changeset, unit, 10)

    assert Unit.enqueued_number(changeset, unit) == 20
  end

  test "should cancel unit queue item" do
    villa = build(:villa) |> with_unit_queue |> Repo.insert!

    {:ok, new_villa} =
      change(villa)
      |> UnitQueueItem.dequeue(List.last(villa.unit_queue_items))
      |> Repo.update

    assert length(new_villa.unit_queue_items) == length(villa.unit_queue_items) - 1
  end

  test "should recruit in discrete steps", %{unit: unit} do
    changeset = build(:villa) |> with_unit_queue |> change

    total_number = Unit.virtual_number(changeset, unit)

    for i <- 1..10 do
      process_until = LaFamiglia.DateTime.from_now(microseconds: Unit.build_time(unit, i))

      changeset = Villa.process_units_virtually_until(changeset, process_until)

      assert total_number == Unit.virtual_number(changeset, unit)
      assert Unit.virtual_number(changeset, unit) == Unit.number(changeset, unit) + Unit.enqueued_number(changeset, unit)
    end
  end

  test "does not recruit more units than enqueued", %{unit: unit} do
    yesterday =
      LaFamiglia.DateTime.from_now(seconds: -86400)
    until =
      LaFamiglia.DateTime.from_now(microseconds: trunc(Unit.build_time(unit) * 0.9))

    changeset =
      build(:villa)
      |> change
      |> put_change(:units_recruited_until, yesterday)
      |> UnitQueueItem.enqueue(unit, 1)
      |> Villa.process_units_virtually_until(until)

    assert Unit.number(changeset, unit) == 0
    assert Unit.virtual_number(changeset, unit) == 1

    until = LaFamiglia.DateTime.from_now(microseconds: trunc(Unit.build_time(unit) * 1.1))

    changeset =
      changeset
      |> Villa.process_units_virtually_until(until)

    assert Unit.number(changeset, unit) == 1
  end

  test "should refund costs", %{unit: unit} do
    villa = build(:villa)
    changeset = villa |> change |> UnitQueueItem.enqueue(unit, 1)

    resources = Resource.filter(villa)

    [item] = get_field(changeset, :unit_queue_items)

    villa = UnitQueueItem.dequeue(changeset, item) |> apply_changes

    # It is assumed that the recruitment of the first unit has been started.
    # Thus, no refunds are to be expected.
    assert resources != Resource.filter(villa)
  end
end
