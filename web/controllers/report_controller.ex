defmodule LaFamiglia.ReportController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player
  alias LaFamiglia.Report

  plug :load_reports

  def index(conn, _params) do
    conn
    |> assign(:report, %Report{})
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    report      = Repo.get(Report, id)
    report_data = LaFamiglia.ReportData.from_map(report.data)

    conn
    |> assign(:report, report)
    |> assign(:report_data, report_data)
    |> render("show.html")
  end

  defp load_reports(conn, _params) do
    reports =
      from(r in assoc(conn.assigns.current_player, :reports),
        order_by: [desc: r.delivered_at])
      |> Repo.all

    conn
    |> assign(:reports, reports)
  end
end
