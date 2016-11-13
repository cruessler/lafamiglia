defmodule LaFamiglia.MapController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Villa

  def show(conn, %{"x" => x, "y" => y}) do
    x = String.to_integer(x)
        |> max(0)
        |> min(Villa.max_x)
    y = String.to_integer(y)
        |> max(0)
        |> min(Villa.max_y)

    conn =
      conn
      |> assign(:center_x, x)
      |> assign(:center_y, y)

    render(conn, :show)
  end
end
