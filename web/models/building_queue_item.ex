defmodule LaFamiglia.BuildingQueueItem do
  use LaFamiglia.Web, :model

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
end
