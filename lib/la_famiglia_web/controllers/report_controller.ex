defmodule LaFamigliaWeb.ReportController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.{Villa, Report}

  plug :load_grouped_reports
  plug :load_villa_grouped_by

  def index(conn, params) do
    query =
      from(r in assoc(conn.assigns.current_player, :reports),
        order_by: [desc: :delivered_at]
      )

    query =
      case params do
        %{"villa_id" => villa_id} ->
          villa_id = String.to_integer(villa_id)

          from(r in query,
            join: v in Villa,
            on: v.id == r.origin_id or v.id == r.target_id,
            where: v.id == ^villa_id
          )

        _ ->
          query
      end

    reports = Repo.all(query)

    conn
    |> assign(:reports, reports)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    report =
      Repo.get!(assoc(conn.assigns.current_player, :reports), id)
      |> Report.preload_payload()

    payload = Report.payload(report)

    report_name =
      payload.__struct__
      |> Atom.to_string()
      |> Phoenix.Naming.resource_name()

    conn
    |> assign(:report, report)
    |> assign(:report_name, report_name <> ".html")
    |> render("show.html")
  end

  defp load_villa_grouped_by(%{params: %{"villa_id" => villa_id}} = conn, _) do
    villa = Repo.get!(Villa, villa_id)

    conn
    |> assign(:grouped_by, villa)
  end

  defp load_villa_grouped_by(%{params: %{"id" => report_id}} = conn, _) do
    report = Repo.get!(assoc(conn.assigns.current_player, :reports), report_id)

    conn
    |> assign(:grouped_by, [%{id: report.origin_id}, %{id: report.target_id}])
  end

  defp load_villa_grouped_by(conn, _) do
    conn
    |> assign(:grouped_by, nil)
  end

  defp load_grouped_reports(conn, _params) do
    current_player = conn.assigns.current_player

    grouped_reports =
      from(r in Report,
        join: v in Villa,
        on: v.id == r.origin_id or v.id == r.target_id,
        group_by: v.id,
        order_by: [desc: max(r.delivered_at)],
        where: r.player_id == ^current_player.id,
        select: %{
          delivered_at: max(r.delivered_at),
          villa: %{id: v.id, name: v.name, x: v.x, y: v.y}
        }
      )
      |> Repo.all()

    conn
    |> assign(:grouped_reports, grouped_reports)
  end
end
