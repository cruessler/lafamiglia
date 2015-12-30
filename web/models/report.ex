defmodule LaFamiglia.Report do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Player
  alias LaFamiglia.RelatedReportVilla

  schema "reports" do
    belongs_to :player, Player

    field :title, :string
    field :data, :map
    field :read, :boolean

    field :delivered_at, Ecto.DateTime

    has_many :related_reports_villas, {"related_reports_villas", RelatedReportVilla},
             foreign_key: :related_report_id
    has_many :related_villas, through: [:related_reports_villas, :villa]

    timestamps
  end

  before_insert :set_delivered_at
  before_insert :set_default_values

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
  end

  defp set_delivered_at(changeset) do
    put_change(changeset, :delivered_at, LaFamiglia.DateTime.now)
  end

  defp set_default_values(changeset) do
    put_change(changeset, :read, false)
  end
end
