defmodule LaFamiglia.RelatedReportVilla do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Report
  alias LaFamiglia.Villa

  @primary_key false

  schema "related_reports_villas" do
    belongs_to :related_report, Report
    belongs_to :villa, Villa

    timestamps
  end

  @required_fields ~w(related_report_id villa_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, [])
    |> assoc_constraint(:related_report)
    |> assoc_constraint(:villa)
  end
end
