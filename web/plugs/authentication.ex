defmodule LaFamiglia.Plugs.Authentication do
  import Plug.Conn
  import Phoenix.Controller

  alias LaFamiglia.Repo
  alias LaFamiglia.Player

  def init(logged_out_path), do: logged_out_path

  def call(conn, logged_out_path) do
    conn
    |> authenticate(logged_out_path)
  end

  defp authenticate(conn, logged_out_path) do
    if player = load_player_from_session(conn) do
      conn
      |> assign(:current_player, player)
    else
      conn
      |> redirect(to: logged_out_path)
      |> halt
    end
  end

  defp load_player_from_session(conn) do
    id = get_session(conn, :current_player_id)
    if id, do: Repo.get(Player, id)
  end
end
