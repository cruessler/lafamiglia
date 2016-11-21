defmodule LaFamiglia.Api.MapController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Villa

  @max_length 20

  def show(conn, %{"min_x" => min_x, "min_y" => min_y,
                   "max_x" => max_x, "max_y" => max_y}) do
    min_x = String.to_integer(min_x)
            |> max(0)
            |> min(Villa.max_x)
    min_y = String.to_integer(min_y)
            |> max(0)
            |> min(Villa.max_y)
    max_x = String.to_integer(max_x)
            |> max(min_x)
            |> min(min_x + @max_length)
            |> min(Villa.max_x)
    max_y = String.to_integer(max_y)
            |> max(min_y)
            |> min(min_y + @max_length)
            |> min(Villa.max_y)

    villas =
      from(v in Villa,
        join: p in assoc(v, :player),
        select: %{id: v.id, name: v.name, x: v.x, y: v.y,
                  player: %{id: p.id, name: p.name}},
        where: v.x >= ^min_x and v.x <= ^max_x
               and v.y >= ^min_y and v.y <= ^max_y)
      |> Repo.all
      |> Enum.map(fn(v) -> add_urls(v, conn) end)

    render conn, :show, villas: villas
  end

  defp add_urls(villa, conn) do
    villa
    |> add_url_for_action(conn)
    |> add_url_for_reports(conn)
  end

  defp add_url_for_action(villa, conn) do
    if villa.player.id == conn.assigns.current_player.id do
      Map.put(villa, :switch_to_url, villa_url(conn, :show, villa.id))
    else
      Map.put(villa, :attack_url,
        villa_attack_movement_url(conn, :new, conn.assigns.current_villa.id,
                                              target_id: villa.id))
    end
  end

  defp add_url_for_reports(villa, conn) do
    Map.put(villa, :reports_url, villa_report_url(conn, :index, villa.id))
  end
end