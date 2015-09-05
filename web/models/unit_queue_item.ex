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
    completed_at = completed_at(villa.unit_queue_items)

    time_diff = if List.first(villa.unit_queue_items) == item do
      LaFamiglia.DateTime.time_diff(item.completed_at, LaFamiglia.DateTime.now)
    else
      item.build_time
    end

    unit        = Unit.get_by_id(item.unit_id)
    number_left = units_recruited_between(item, LaFamiglia.DateTime.now, completed_at)

    Repo.transaction fn ->
      Repo.delete!(item)

      Enum.map villa.unit_queue_items, fn(i) ->
        if i.completed_at > item.completed_at do
          changeset(i, %{completed_at: LaFamiglia.DateTime.add_seconds(i.completed_at, -time_diff)})
          |> Repo.update!
        end
      end

      # Don’t refund resources for the first unit that has already started
      # being recruited.
      refunds =
        unit.costs
        |> Enum.map(fn({k, v}) -> {k, v * (number_left - 1)} end)
        |> Enum.into(%{})
      new_villa = Villa.add_resources(villa, refunds)

      Villa.changeset(villa, Villa.get_resources(new_villa))
      |> Ecto.Changeset.put_change(:supply, villa.supply - unit.supply * number_left)
      |> Repo.update!

      item
    end
  end
end
