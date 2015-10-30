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

    costs      = unit.costs
                 |> Enum.map(fn({k, v}) -> {k, v * number} end)
                 |> Enum.into(%{})
    supply     = unit.supply * number
    build_time = unit.build_time * number
    completed_at =
      completed_at(unit_queue_items)
      |> LaFamiglia.DateTime.add_seconds(build_time)

    cond do
      !Villa.has_supply?(changeset, supply) ->
        {:error, "You don’t have enough supply to recruit these units."}
      !Villa.has_resources?(changeset, costs) ->
        {:error, "You don’t have enough resources to recruit these units."}
      true ->
        new_item = Ecto.Model.build(villa, :unit_queue_items,
                                    unit_id: unit.id,
                                    number: number,
                                    build_time: build_time / 1,
                                    completed_at: completed_at)

        changeset
        |> Villa.subtract_resources(costs)
        |> put_change(:supply, villa.supply + supply)
        |> put_change(:unit_queue_items, unit_queue_items ++ [new_item])
        |> Repo.update
    end
  end

  def dequeue!(%Changeset{model: villa} = changeset, item) do
    unit_queue_items = get_field(changeset, :unit_queue_items)

    time_diff = case List.first(unit_queue_items) do
      ^item ->
        LaFamiglia.DateTime.time_diff(LaFamiglia.DateTime.now, item.completed_at)
      _ ->
        item.build_time
    end

    unit        = Unit.get_by_id(item.unit_id)
    number_left = units_recruited_between(item, LaFamiglia.DateTime.now, item.completed_at)

    # Don’t refund resources for the first unit that has already started
    # being recruited.
    refunds =
      unit.costs
      |> Enum.map(fn({k, v}) -> {k, v * (number_left - 1)} end)
      |> Enum.into(%{})

    new_unit_queue_items =
      unit_queue_items
      |> Enum.filter(fn(i) -> i != item end)
      |> Enum.map fn(other_item) ->
        case Ecto.DateTime.compare(other_item.completed_at, item.completed_at) do
          :gt ->
            new_completed_at = LaFamiglia.DateTime.add_seconds(other_item.completed_at, -time_diff)
            new_other_item =
              %__MODULE__{other_item | completed_at: new_completed_at}

            LaFamiglia.EventQueue.cast({:cancel_event, other_item})
            LaFamiglia.EventQueue.cast({:new_event, new_other_item})

            new_other_item
          _ ->
            other_item
        end
      end

    changeset
    |> Villa.add_resources(refunds)
    |> put_change(:supply, villa.supply - unit.supply * number_left)
    |> put_change(:unit_queue_items, new_unit_queue_items)
    |> Repo.update
  end
end
