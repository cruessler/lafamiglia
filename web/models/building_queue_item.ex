defmodule LaFamiglia.BuildingQueueItem do
  use LaFamiglia.Web, :model

  use Ecto.Model.Callbacks

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

  def completed_at([]) do
    LaFamiglia.DateTime.now
  end
  def completed_at([_|_] = queue) do
    List.last(queue).completed_at
  end

  def enqueue(villa, building) do
    villa = Repo.preload(villa, :building_queue_items)

    level        = Building.virtual_level(villa, building)
    costs        = building.costs.(level)
    build_time   = building.build_time.(level)
    completed_at = LaFamiglia.DateTime.add_seconds(completed_at(villa.building_queue_items), build_time)

    changeset = Villa.subtract_resources(villa, costs)

    cond do
      level >= building.maxlevel ->
        {:error, Ecto.Changeset.add_error(changeset, :building_queue_items, "Building already at maxlevel.")}
      !Villa.has_resources?(villa, costs) ->
        {:error, Ecto.Changeset.add_error(changeset, :building_queue_items, "Not enough resources.")}
      true ->
        new_item = Ecto.Model.build(villa, :building_queue_items,
                                    building_id: building.id,
                                    build_time: build_time / 1,
                                    completed_at: completed_at)

        changeset
        |> Ecto.Changeset.change(building_queue_items: villa.building_queue_items ++ [new_item])
        |> Repo.update
    end
  end
end
