defmodule LaFamiglia.UnitQueueItem do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset

  import LaFamiglia.Queue

  alias LaFamiglia.Villa
  alias LaFamiglia.Unit

  schema "unit_queue_items" do
    field :unit_id, :integer
    field :number, :integer
    field :build_time, :integer
    field :completed_at, :utc_datetime_usec

    belongs_to :villa, Villa

    field :processed, :boolean, virtual: true

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:unit_id, :number, :completed_at, :villa_id])
    |> validate_required([:unit_id, :number, :completed_at, :villa_id])
  end

  defp start_time(item) do
    item.completed_at
    |> Timex.shift(microseconds: -item.build_time)
  end

  @doc """
  This function return the number of units recruited between time_begin and
  time_start.

  It never returns a number greater than `item.number`. This makes sure a
  correct result is returned if `time_begin < start_time(item)`.

  It returns incorrect results when the game speed is changed once an order has
  been saved to the database.
  """
  def units_recruited_between(item, time_begin, time_end) do
    start_time = start_time(item)
    time_begin = LaFamiglia.DateTime.max(start_time, time_begin)
    training_time = Unit.get(item.unit_id) |> Unit.training_time()

    start_number =
      trunc(Timex.diff(time_begin, start_time, :microseconds) / training_time)
    end_number =
      trunc(Timex.diff(time_end, start_time, :microseconds) / training_time)

    end_number - start_number
  end

  def enqueue(%Changeset{data: villa} = changeset, unit, number) do
    unit_queue_items = get_field(changeset, :unit_queue_items)

    costs      = Map.new(unit.costs, fn({k, v}) -> {k, v * number} end)
    supply     = unit.supply * number
    training_time = Unit.training_time(unit, number)
    completed_at =
      completed_at(unit_queue_items)
      |> Timex.shift(microseconds: training_time)

    new_item = Ecto.build_assoc(villa, :unit_queue_items,
                                unit_id: unit.id,
                                number: number,
                                build_time: training_time,
                                completed_at: completed_at)

    changeset
    |> Villa.recruit_changeset(new_item, costs, supply)
  end

  def dequeue(%Changeset{data: villa} = changeset, item) do
    unit_queue_items = get_field(changeset, :unit_queue_items)

    time_diff   = build_time_left(unit_queue_items, item)
    unit        = Unit.get(item.unit_id)
    number_left = units_recruited_between(item, LaFamiglia.DateTime.now, item.completed_at)

    # Don’t refund resources for the first unit that has already started
    # being recruited.
    refunds =
      unit.costs
      |> Map.new(fn({k, v}) -> {k, v * (number_left - 1)} end)

    new_unit_queue_items =
      unit_queue_items
      |> shift_later_items(item, time_diff)
      |> Enum.map(&change/1)

    changeset
    |> Villa.add_resources(refunds)
    |> put_change(:supply, villa.supply - unit.supply * number_left)
    |> put_assoc(:unit_queue_items, new_unit_queue_items)
  end
end
