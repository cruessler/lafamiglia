defmodule LaFamiglia.ReportController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player
  alias LaFamiglia.Report

  plug :load_grouped_reports

  def index(conn, params) do
    query =
      from(r in assoc(conn.assigns.current_player, :reports),
        order_by: [desc: :delivered_at])

    query =
      case params do
        %{"villa_id" => villa_id} ->
          villa_id = String.to_integer(villa_id)

          from(r in query,
            join: v in assoc(r, :related_villas),
            where: v.id == ^villa_id)
        _ ->
          query
      end

    reports = Repo.all(query)

    conn
    |> assign(:report, %Report{})
    |> assign(:reports, reports)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    report      = Repo.get(Report, id)

    conn
    |> assign(:report, report)
    |> render("show.html")
  end

  defp load_grouped_reports(conn, _params) do
    current_player_id = conn.assigns.current_player.id

    grouped_reports =
      from(r in Report,
        join: v in assoc(r, :related_villas),
        group_by: v.id,
        order_by: [desc: max(r.delivered_at)],
        where: r.player_id == ^current_player_id and v.player_id != ^current_player_id,
        select: %{delivered_at: max(r.delivered_at), villa: %{id: v.id, name: v.name, x: v.x, y: v.y}})
      |> Repo.all
      # Using max(…) in a select makes Ecto not cast the respective column
      # automatically.
      |> Enum.map fn(r) -> update_in(r, [:delivered_at], &Ecto.DateTime.cast!(&1)) end

    conn
    |> assign(:grouped_reports, grouped_reports)
  end
end
