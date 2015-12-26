defmodule LaFamiglia.ReportView do
  use LaFamiglia.Web, :view

  def li_class_for(report, shown_report) do
    if shown_report.id == report.id do
      "selected"
    end
  end
end
