defmodule LaFamiglia.ReportController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.{Villa, Report}

  plug :load_grouped_reports
  plug :load_villa_grouped_by

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
    |> assign(:reports, reports)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    report = Repo.get!(assoc(conn.assigns.current_player, :reports), id)

    conn
    |> assign(:report, report)
    |> render("show.html")
  end

  defp load_villa_grouped_by(%{params: %{"villa_id" => villa_id}} = conn, _) do
    villa =
      from(v in Villa, where: v.id == ^villa_id)
      |> Repo.one

    conn
    |> assign(:grouped_by, villa)
  end
  defp load_villa_grouped_by(%{params: %{"id" => report_id}} = conn, _) do
    villas =
      from(v in Villa,
        join: r in assoc(v, :related_reports),
        where: r.id == ^report_id,
        select: %{id: v.id})
      |> Repo.all

    conn
    |> assign(:grouped_by, villas)
  end
  defp load_villa_grouped_by(conn, _) do
    conn
    |> assign(:grouped_by, nil)
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
      |> Enum.map(fn(r) -> update_in(r, [:delivered_at], &Ecto.DateTime.cast!(&1)) end)

    conn
    |> assign(:grouped_reports, grouped_reports)
  end
end
