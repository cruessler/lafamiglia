defmodule LaFamiglia.ReportView do
  use LaFamiglia.Web, :view

  def li_class_for(report, nil), do: ""
  def li_class_for(report, grouped_by_villa) do
    if grouped_by_villa.id == report.villa.id do
      "selected"
    end
  end
end
