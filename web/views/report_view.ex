defmodule LaFamiglia.ReportView do
  use LaFamiglia.Web, :view

  def li_class_for(_, nil), do: ""
  def li_class_for(report, [related_villa1, related_villa2]) do
    if report.villa.id == related_villa1.id || report.villa.id == related_villa2.id do
      "selected"
    end
  end
  def li_class_for(report, grouped_by_villa) do
    if grouped_by_villa.id == report.villa.id do
      "selected"
    end
  end
end
