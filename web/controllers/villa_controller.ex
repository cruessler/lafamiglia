defmodule LaFamiglia.VillaController do
  use LaFamiglia.Web, :controller

  alias Ecto.Changeset

  def index(conn, _params) do
    conn
    |> assign(:villas, assoc(conn.assigns.current_player, :villas) |> Repo.all)
    |> render("index.html")
  end

  # Matching the id is not necessary here as that is done implicitly in
  # VillaLoader.load_villa_from_query_params.
  # Either conn.assigns.current_villa.id == conn.params.id is true or
  # current_villa has been loaded by a fallback.
  def show(conn, _params) do
    conn
    |> assign(:current_villa,
         conn.assigns.current_villa |> Repo.preload(:building_queue_items))
    |> render("show.html")
  end
end
