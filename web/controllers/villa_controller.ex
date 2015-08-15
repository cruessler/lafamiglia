defmodule LaFamiglia.VillaController do
  use LaFamiglia.Web, :controller
  use Ecto.Model

  def index(conn, _params) do
    conn
    |> assign(:villas, assoc(conn.assigns.current_player, :villas) |> Repo.all)
    |> render("index.html")
  end

  # Matching the id is not necessary here as that is done implicitly in
  # VillaLoader#load_villa_from_query_params.
  def show(conn, _params) do
    render(conn, "show.html")
  end
end
