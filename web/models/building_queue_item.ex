defmodule LaFamiglia.BuildingQueueItem do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset

  import LaFamiglia.Queue

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

  after_insert LaFamiglia.EventCallbacks, :after_insert
  after_update LaFamiglia.EventCallbacks, :after_update
  after_delete LaFamiglia.EventCallbacks, :after_delete

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
    |> Map.new(fn({k, v}) -> {k, v * refund_ratio} end)
  end

  @doc """
  This function adds an item to the building queue.
  """
  def enqueue!(%Changeset{model: villa} = changeset, building) do
    # Since `villa.building_queue_items` is never changed in the webapp except
    # via `enqueue!` and `dequeue!`, it is safe to assume that we can simply use
    # `villa.building_queue_items` to access the current building queue.
    villa     = Repo.preload(villa, :building_queue_items)
    changeset = %Changeset{changeset | model: villa}

    level        = Building.virtual_level(villa, building)
    costs        = building.costs.(level)
    build_time   = building.build_time.(level)
    completed_at =
      completed_at(villa.building_queue_items)
      |> LaFamiglia.DateTime.add_seconds(build_time)

    new_item = Ecto.Model.build(villa, :building_queue_items,
                                building_id: building.id,
                                build_time: build_time / 1,
                                completed_at: completed_at)

    changeset
    |> Villa.build(new_item, costs)
    |> Repo.update
  end

  def dequeue!(%Changeset{model: villa} = changeset, item) do
    villa = Repo.preload(villa, :building_queue_items)
    changeset = %Changeset{changeset | model: villa}

    unless last_of_its_kind?(villa.building_queue_items, item) do
      add_error(changeset, :building_queue_items, "You can only cancel the last building of its kind.")
    else
      time_diff = build_time_left(villa.building_queue_items, item)
      refunds   = refunds(villa, item, time_diff)
      new_building_queue_items =
        villa.building_queue_items
        |> remove_item(item)
        |> shift_later_items(item, time_diff)

      changeset
      |> Villa.add_resources(refunds)
      |> put_assoc(:building_queue_items, new_building_queue_items)
      |> Repo.update
    end
  end
end
