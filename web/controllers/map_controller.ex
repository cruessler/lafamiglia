defmodule LaFamiglia.MapController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Villa
  alias LaFamiglia.Unit

  def show(conn, %{"x" => x, "y" => y}) do
    x =
      String.to_integer(x)
      |> max(0)
      |> min(Villa.max_x())

    y =
      String.to_integer(y)
      |> max(0)
      |> min(Villa.max_y())

    current_villa = conn.assigns.current_villa

    flags =
      %{
        center: %{x: x, y: y},
        currentVilla: Map.take(current_villa, [:id, :name, :x, :y]),
        unitNumbers: Unit.filter(current_villa),
        csrfToken: get_csrf_token
      }
      |> Jason.encode!()

    conn =
      conn
      |> assign(:flags, flags)

    render(conn, :show)
  end
end
