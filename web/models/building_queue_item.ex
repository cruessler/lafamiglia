defmodule LaFamiglia.BuildingQueueItem do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  schema "building_queue_items" do
    field :building_id, :integer
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
    old_queue = assoc(villa, :building_queue_items) |> Repo.all

    level        = Building.virtual_level(villa, building)
    costs        = building.costs.(level)
    build_time   = building.build_time.(level)
    completed_at = LaFamiglia.DateTime.add_seconds(completed_at(old_queue), build_time)

    new_item = Ecto.Model.build(villa, :building_queue_items,
                                building_id: building.id,
                                completed_at: completed_at)

    villa = Villa.subtract_resources(villa, costs)

    Repo.transaction fn ->
      Repo.insert!(new_item)
      Repo.update!(villa)
    end
  end
end
