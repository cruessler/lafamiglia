defmodule LaFamiglia.MapController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Villa

  def show(conn, %{"x" => x, "y" => y}) do
    x = String.to_integer(x) |> max(0) |> min(Villa.max_x)
    y = String.to_integer(y) |> max(0) |> min(Villa.max_y)

    conn =
      conn
      |> assign(:center_x, x)
      |> assign(:center_y, y)

    render(conn, :show)
  end

  def show(conn, %{"min_x" => min_x, "min_y" => min_y,
                   "max_x" => max_x, "max_y" => max_y}) do
    villas =
      from(v in Villa,
        join: p in assoc(v, :player),
        select: %{id: v.id, name: v.name, x: v.x, y: v.y,
                  player: %{id: p.id, name: p.name}},
        where: v.x >= ^min_x and v.x <= ^max_x
               and v.y >= ^min_y and v.y <= ^max_y)
      |> Repo.all

    render conn, :show, villas: villas
  end
end
