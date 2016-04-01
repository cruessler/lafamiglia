defmodule LaFamiglia.UnitQueueItem do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset
  alias Ecto.Multi

  import LaFamiglia.Queue

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.Unit

  schema "unit_queue_items" do
    field :unit_id, :integer
    field :number, :integer
    field :build_time, :float
    field :completed_at, Ecto.DateTime

    belongs_to :villa, Villa

    field :processed, :boolean, virtual: true

    timestamps
  end

  @required_fields ~w(unit_id number completed_at villa_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  defp start_time(item) do
    LaFamiglia.DateTime.add_seconds(item.completed_at, -item.build_time)
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
    time_begin = max(start_time, time_begin)
    build_time = Unit.get(item.unit_id) |> Unit.build_time()

    start_number = trunc(LaFamiglia.DateTime.time_diff(start_time, time_begin) / build_time)
    end_number = trunc(LaFamiglia.DateTime.time_diff(start_time, time_end) / build_time)

    end_number - start_number
  end

  def enqueue(%Changeset{data: villa} = changeset, unit, number) do
    unit_queue_items = get_field(changeset, :unit_queue_items)

    costs      = Map.new(unit.costs, fn({k, v}) -> {k, v * number} end)
    supply     = unit.supply * number
    build_time = Unit.build_time(unit, number)
    completed_at =
      completed_at(unit_queue_items)
      |> LaFamiglia.DateTime.add_seconds(build_time)

    new_item = Ecto.build_assoc(villa, :unit_queue_items,
                                unit_id: unit.id,
                                number: number,
                                build_time: build_time / 1,
                                completed_at: completed_at)

    Multi.new
    |> Multi.update(:villa, Villa.recruit_changeset(changeset, new_item, costs, supply))
    |> Multi.insert(:unit_queue_item, new_item)
    |> Multi.run(:send_to_queue, &LaFamiglia.EventCallbacks.send_to_queue/1)
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
      |> Enum.map &Changeset.change/1

    changeset =
      changeset
      |> Villa.add_resources(refunds)
      |> put_change(:supply, villa.supply - unit.supply * number_left)
      |> put_assoc(:unit_queue_items, new_unit_queue_items)

    Multi.new
    |> Multi.update(:villa, changeset)
    |> Multi.delete(:unit_queue_item, item)
    |> Multi.run(:drop_from_queue, &LaFamiglia.EventCallbacks.drop_from_queue/1)
  end
end
