defmodule LaFamiglia.Plugs.VillaLoader do
  @moduledoc """
  Switching a session’s current villa is done implicitly through
  load_villa_from_query_params, matching every request that contains
  a villa id. Subsequent requests that don’t specify a villa id, e. g. attack
  orders, will then refer to that villa.
  """

  import Plug.Conn

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> load_villa
  end

  defp load_villa_from_query_params(%Plug.Conn{ path_info: ["villas"|_], params: %{"id" => id} } = _conn) do
    Repo.get(Villa, id)
  end
  defp load_villa_from_query_params(_conn) do
    nil
  end

  defp load_villa_from_session(conn) do
    case get_session(conn, :current_villa_id) do
      nil -> nil
      id  -> Repo.get(Villa, id)
    end
  end

  defp load_first_villa(conn) do
    Repo.all(Villa, player_id: conn.assigns.current_player.id,
                    limit: 1)
      |> List.first
  end

  defp create_new_villa(conn) do
    Villa.create_for(conn.assigns.current_player)
  end

  defp load_villa(conn) do
    villa =
      load_villa_from_query_params(conn)
      || load_villa_from_session(conn)
      || load_first_villa(conn)
      || create_new_villa(conn)

    if villa do
      conn
      |> assign(:current_villa, villa)
      |> put_session(:current_villa_id, villa.id)
    else
      conn
      |> delete_session(:current_villa_id)
    end
  end
end
