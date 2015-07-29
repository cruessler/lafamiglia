defmodule LaFamiglia.VillaController do
  use LaFamiglia.Web, :controller
  use Ecto.Model

  alias LaFamiglia.Session
  alias LaFamiglia.Player
  alias LaFamiglia.Villa

  plug :fetch_player
  plug :fetch_villa
  plug :check_for_villa

  def index(conn, _) do
    conn
    |> assign(:villas, assoc(conn.assigns.current_player, :villas) |> Repo.all)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.html")
  end

  defp check_for_villa(conn, _) do
    case conn.assigns[:current_villa] do
      nil ->
        conn
        |> put_flash(:error, "There is no villa left for you.")
        |> redirect(to: page_path(conn, :index))
      _ -> conn
    end
  end

  defp fetch_player(conn, _) do
    conn
    |> assign(:current_player, Repo.get(Player, get_session(conn, :current_player)))
  end

  defp fetch_villa(conn, _) do
    case conn.assigns[:current_villa] do
      nil ->
        villa_id = get_session(conn, :current_villa)

        villa = unless is_nil(villa_id) do
          Repo.get_by(Villa, player_id: get_session(conn, :current_player),
                             id: villa_id)
        end

        villa = villa
        || Repo.get_by(Villa, player_id: get_session(conn, :current_player))
        || Villa.create_for(Session.current_player(conn))

        assign(conn, :current_villa, villa)
      _ -> conn
    end
  end
end
