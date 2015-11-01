defmodule LaFamiglia.ComebackMovement do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  schema "comeback_movements" do
    belongs_to :origin, Villa
    belongs_to :target, Villa

    field :unit_1, :integer
    field :unit_2, :integer

    field :resource_1, :integer
    field :resource_2, :integer
    field :resource_3, :integer

    field :arrives_at, Ecto.DateTime

    timestamps
  end

  after_insert LaFamiglia.EventCallbacks, :after_insert

  @required_fields ~w(origin_id target_id arrives_at
                      unit_1 unit_2)
  @optional_fields ~w(resource_1 resource_2 resource_3)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def arrive!(comeback) do
    Repo.delete(comeback)
  end
end
