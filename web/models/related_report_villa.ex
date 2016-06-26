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

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:related_report_id, :villa_id])
    |> validate_required([:related_report_id, :villa_id])
    |> assoc_constraint(:related_report)
    |> assoc_constraint(:villa)
  end
end
