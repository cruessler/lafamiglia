defmodule LaFamiglia.ComebackMovement do
  use LaFamiglia.Web, :model

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

  @required_fields ~w(origin_id target_id
                      unit_1 unit_2
                      resource_1 resource_2 resource_3)
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
