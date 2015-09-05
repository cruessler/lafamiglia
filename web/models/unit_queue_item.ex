defmodule LaFamiglia.UnitQueueItem do
  use LaFamiglia.Web, :model

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

  def enqueue!(old_villa, unit, number) do
    old_villa = Repo.preload(old_villa, :unit_queue_items)
    villa     = Villa.process_virtually_until(old_villa, LaFamiglia.DateTime.now)

    costs      = unit.costs
                 |> Enum.map(fn({k, v}) -> {k, v * number} end)
                 |> Enum.into(%{})
    supply     = unit.supply * number
    build_time = unit.build_time * number
    completed_at =
      completed_at(villa.unit_queue_items)
      |> LaFamiglia.DateTime.add_seconds(build_time)

    cond do
      !Villa.has_supply?(villa, supply) ->
        {:error, "You don’t have enough supply to recruit these units."}
      !Villa.has_resources?(villa, costs) ->
        {:error, "You don’t have enough resources to recruit these units."}
      true ->
        new_item = Ecto.Model.build(villa, :unit_queue_items,
                                    unit_id: unit.id,
                                    number: number,
                                    build_time: build_time / 1,
                                    completed_at: completed_at)

        villa = Villa.subtract_resources(villa, costs)

        Repo.transaction fn ->
          Villa.changeset(old_villa, Map.from_struct(villa)
                                     |> Map.put(:supply, villa.supply + supply))
          |> Repo.update!

          Repo.insert!(new_item)
        end
    end
  end

  def dequeue!(villa, item) do
    villa        = Repo.preload(villa, :unit_queue_items)

    time_diff = if List.first(villa.unit_queue_items) == item do
      LaFamiglia.DateTime.time_diff(LaFamiglia.DateTime.now, item.completed_at)
    else
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

    new_villa =
      villa
      |> Villa.process_virtually_until(LaFamiglia.DateTime.now)
      |> Villa.add_resources(refunds)

    Repo.transaction fn ->
      Repo.delete!(item)

      Enum.map villa.unit_queue_items, fn(other_item) ->
        if Ecto.DateTime.compare(other_item.completed_at, item.completed_at) == :gt do
          new_other_item =
            other_item
            |> changeset(%{completed_at: LaFamiglia.DateTime.add_seconds(other_item.completed_at, -time_diff)})
            |> Repo.update!

          LaFamiglia.EventQueue.cast({:cancel_event, other_item})
          LaFamiglia.EventQueue.cast({:new_event, new_other_item})
        end
      end

      Villa.changeset(villa, Villa.get_resources(new_villa))
      |> Ecto.Changeset.put_change(:supply, villa.supply - unit.supply * number_left)
      |> Ecto.Changeset.put_change(unit.key, Map.get(new_villa, unit.key))
      |> Repo.update!

      item
    end
  end
end
