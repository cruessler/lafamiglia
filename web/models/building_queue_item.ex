defmodule LaFamiglia.BuildingQueueItem do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset
  alias Ecto.Multi

  import LaFamiglia.Queue

  alias LaFamiglia.Building

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  schema "building_queue_items" do
    field :building_id, :integer
    field :build_time, :float
    field :completed_at, Ecto.DateTime

    belongs_to :villa, Villa

    field :processed, :boolean, virtual: true

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

  defp first_of_its_kind?([], _item), do: true
  defp first_of_its_kind?([item|rest], item), do: true
  defp first_of_its_kind?([first|rest], item) do
    cond do
      first.building_id == item.building_id -> false
      true -> first_of_its_kind?(rest, item)
    end
  end

  def last_of_its_kind?(queue, item) do
    queue
    |> Enum.reverse
    |> first_of_its_kind?(item)
  end

  def refunds(villa, item, time_diff) do
    building = Building.get(item.building_id)

    previous_level = Building.virtual_level(villa, building) - 1
    refund_ratio   = time_diff / item.build_time

    building.costs.(previous_level)
    |> Map.new(fn({k, v}) -> {k, v * refund_ratio} end)
  end

  @doc """
  This function adds an item to the building queue.
  """
  def enqueue(%Changeset{data: villa} = changeset, building) do
    # Since `villa.building_queue_items` is never changed in the webapp except
    # via `enqueue` and `dequeue`, it is safe to assume that we can simply use
    # `villa.building_queue_items` to access the current building queue.
    villa     = Repo.preload(villa, :building_queue_items)
    changeset = %Changeset{changeset | data: villa}

    level        = Building.virtual_level(villa, building)
    costs        = building.costs.(level)
    build_time   = Building.build_time(building, level)
    completed_at =
      completed_at(villa.building_queue_items)
      |> LaFamiglia.DateTime.add_seconds(build_time)

    new_item = Ecto.build_assoc(villa, :building_queue_items,
                                building_id: building.id,
                                build_time: build_time / 1,
                                completed_at: completed_at)

    Multi.new
    |> Multi.update(:villa, Villa.build_changeset(changeset, new_item, costs))
    |> Multi.insert(:building_queue_item, new_item)
    |> Multi.run(:send_to_queue, &LaFamiglia.EventCallbacks.send_to_queue/1)
  end

  def dequeue(%Changeset{data: villa} = changeset, item) do
    villa     = Repo.preload(villa, :building_queue_items)
    changeset = %Changeset{changeset | data: villa}

    if last_of_its_kind?(villa.building_queue_items, item) do
      time_diff = build_time_left(villa.building_queue_items, item)
      refunds   = refunds(villa, item, time_diff)

      new_building_queue_items =
        villa.building_queue_items
        |> shift_later_items(item, time_diff)
        |> Enum.map &Changeset.change/1

      changeset =
        changeset
        |> Villa.add_resources(refunds)
        |> put_assoc(:building_queue_items, new_building_queue_items)

      Multi.new
      |> Multi.update(:villa, changeset)
      |> Multi.delete(:building_queue_item, item)
      |> Multi.run(:drop_from_queue, &LaFamiglia.EventCallbacks.drop_from_queue/1)
    else
      changeset =
        changeset
        |> Changeset.put_error(changeset, :building_queue_items, "You can only cancel the last building of its kind.")

      Multi.new
      |> Multi.update(:villa, changeset)
    end
  end
end
