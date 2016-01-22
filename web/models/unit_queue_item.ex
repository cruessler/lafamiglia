defmodule LaFamiglia.UnitQueueItem do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset

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

  after_insert LaFamiglia.EventCallbacks, :after_insert
  after_update LaFamiglia.EventCallbacks, :after_update
  after_delete LaFamiglia.EventCallbacks, :after_delete

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
    LaFamiglia.DateTime.add_seconds(completed_at([item]), -item.build_time)
  end

  def units_recruited_between(item, time_begin, time_end) do
    start_time = start_time(item)
    unit       = Unit.get_by_id(item.unit_id)

    start_number = trunc(LaFamiglia.DateTime.time_diff(start_time, time_begin) / unit.build_time)
    end_number = trunc(LaFamiglia.DateTime.time_diff(start_time, time_end) / unit.build_time)

    end_number - start_number
  end

  def enqueue!(%Changeset{model: villa} = changeset, unit, number) do
    unit_queue_items = get_field(changeset, :unit_queue_items)

    costs      = Map.new(unit.costs, fn({k, v}) -> {k, v * number} end)
    supply     = unit.supply * number
    build_time = unit.build_time * number
    completed_at =
      completed_at(unit_queue_items)
      |> LaFamiglia.DateTime.add_seconds(build_time)

    new_item = Ecto.Model.build(villa, :unit_queue_items,
                                unit_id: unit.id,
                                number: number,
                                build_time: build_time / 1,
                                completed_at: completed_at)

    changeset
    |> Villa.recruit(new_item, costs, supply)
    |> Repo.update
  end

  def dequeue!(%Changeset{model: villa} = changeset, item) do
    unit_queue_items = get_field(changeset, :unit_queue_items)

    time_diff   = build_time_left(unit_queue_items, item)
    unit        = Unit.get_by_id(item.unit_id)
    number_left = units_recruited_between(item, LaFamiglia.DateTime.now, item.completed_at)

    # Don’t refund resources for the first unit that has already started
    # being recruited.
    refunds =
      unit.costs
      |> Map.new(fn({k, v}) -> {k, v * (number_left - 1)} end)

    new_unit_queue_items =
      unit_queue_items
      |> remove_item(item)
      |> shift_later_items(item, time_diff)

    changeset
    |> Villa.add_resources(refunds)
    |> put_change(:supply, villa.supply - unit.supply * number_left)
    |> put_assoc(:unit_queue_items, new_unit_queue_items)
    |> Repo.update
  end
end
