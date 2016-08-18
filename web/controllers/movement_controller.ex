defmodule LaFamiglia.MovementController do
  use LaFamiglia.Web, :controller

  def index(conn, _params) do
    current_player =
      conn.assigns.current_player
      |> Repo.preload(
        [attack_movements: [:origin, :target],
         comeback_movements: [:origin, :target],
         occupations: [:origin, :target]])

    conn
    |> assign(:current_player, current_player)
    |> render("index.html")
  end
end
