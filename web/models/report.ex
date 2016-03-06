defmodule LaFamiglia.Report do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Player
  alias LaFamiglia.Villa
  alias LaFamiglia.RelatedReportVilla

  schema "reports" do
    belongs_to :player, Player

    field :title, :string
    field :data, LaFamiglia.ReportData
    field :read, :boolean

    field :delivered_at, Ecto.DateTime

    many_to_many :related_villas, Villa, join_through: RelatedReportVilla,
                                         join_keys: [related_report_id: :id, villa_id: :id]

    timestamps
  end

  @required_fields ~w(title data player_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> assoc_constraint(:player)
    |> put_change(:delivered_at, LaFamiglia.DateTime.now)
    |> put_change(:read, false)
  end
end
