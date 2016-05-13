defmodule LaFamiglia.Occupation do
  use LaFamiglia.Web, :model

  schema "occupations" do
    field :succeeds_at, Ecto.DateTime

    field :unit_1, :integer
    field :unit_2, :integer

    belongs_to :origin, Villa
    belongs_to :target, Villa

    timestamps
  end

  @required_fields ~w(unit_1 unit_2 succeeds_at origin_id target_id)
  @optional_fields ~w()

  def changeset(model, params \\ :invalid) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
