defmodule LaFamiglia.BuildingQueueItem do
  use LaFamiglia.Web, :model

  use Ecto.Model.Callbacks

  import LaFamiglia.Queue

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  schema "building_queue_items" do
    field :building_id, :integer
    field :build_time, :float
    field :completed_at, Ecto.DateTime

    belongs_to :villa, Villa

    timestamps
  end

  @required_fields ~w(building_id completed_at villa_id)
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

  defp first_of_its_kind?([], _item) do
    true
  end
  defp first_of_its_kind?([h|t], item) do
    cond do
      h == item ->
        true
      h.building_id == item.building_id ->
        false
      true ->
        first_of_its_kind?(t, item)
    end
  end

  def last_of_its_kind?(queue, item) do
    queue
    |> Enum.reverse
    |> first_of_its_kind?(item)
  end

  def refunds(villa, item, time_diff) do
    building = Building.get_by_id(item.building_id)

    previous_level = Building.virtual_level(villa, building) - 1
    refund_ratio   = time_diff / item.build_time

    building.costs.(previous_level)
    |> Enum.map(fn({k, v}) ->
      {k, v * refund_ratio}
    end)
    |> Enum.into(%{})
  end

  def enqueue!(old_villa, building) do
    old_villa = Repo.preload(old_villa, :building_queue_items)
    villa     = Villa.process_virtually_until(old_villa, LaFamiglia.DateTime.now)

    level        = Building.virtual_level(villa, building)
    costs        = building.costs.(level)
    build_time   = building.build_time.(level)
    completed_at =
      completed_at(villa.building_queue_items)
      |> LaFamiglia.DateTime.add_seconds(build_time)

    cond do
      level >= building.maxlevel ->
        {:error, "Building already at maxlevel."}
      !Villa.has_resources?(villa, costs) ->
        {:error, "Not enough resources."}
      true ->
        new_item = Ecto.Model.build(villa, :building_queue_items,
                                    building_id: building.id,
                                    build_time: build_time / 1,
                                    completed_at: completed_at)

        villa = Villa.subtract_resources(villa, costs)

        Repo.transaction fn ->
          Villa.changeset(old_villa, Map.from_struct(villa))
          |> Repo.update!

          Repo.insert!(new_item)
        end
    end
  end

  def dequeue!(villa, item) do
    villa        = Repo.preload(villa, :building_queue_items)

    unless last_of_its_kind?(villa.building_queue_items, item) do
      {:error, "You can only cancel the last building of its kind."}
    else
      time_diff = if item == List.first(villa.building_queue_items) do
        LaFamiglia.DateTime.time_diff(LaFamiglia.DateTime.now, item.completed_at)
      else
        item.build_time
      end

      Repo.transaction fn ->
        Repo.delete!(item)

        Enum.map villa.building_queue_items, fn(other_item) ->
          if Ecto.DateTime.compare(other_item.completed_at, item.completed_at) == :gt do
            new_other_item =
              other_item
              |> changeset(%{completed_at: LaFamiglia.DateTime.add_seconds(other_item.completed_at, -time_diff)})
              |> Repo.update!

            LaFamiglia.EventQueue.cast({:cancel_event, other_item})
            LaFamiglia.EventQueue.cast({:new_event, new_other_item})
          end
        end

        villa
        |> Villa.add_resources(refunds(villa, item, time_diff))
        |> Repo.update!

        item
      end
    end
  end
end
