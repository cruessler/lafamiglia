defmodule LaFamigliaWeb.Plugs.VillaLoader do
  @moduledoc """
  Switching a session’s current villa is done implicitly through
  load_villa_from_query_params, matching every request that contains
  a villa id. Subsequent requests that don’t specify a villa id, e. g. attack
  orders, will then refer to that villa.
  """

  import Plug.Conn

  import Ecto

  alias Ecto.Multi

  alias LaFamiglia.Repo
  alias LaFamiglia.Player
  alias LaFamiglia.Villa

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> load_villa
  end

  defp load_villa_from_query_params(
         %Plug.Conn{path_info: ["villas" | _], params: %{"id" => id}} = conn
       ) do
    assoc(conn.assigns.current_player, :villas) |> Repo.get(id)
  end

  defp load_villa_from_query_params(_conn) do
    nil
  end

  defp load_villa_from_session(conn) do
    case get_session(conn, :current_villa_id) do
      nil -> nil
      id -> assoc(conn.assigns.current_player, :villas) |> Repo.get(id)
    end
  end

  defp load_first_villa(conn) do
    assoc(conn.assigns.current_player, :villas) |> Repo.all() |> List.first()
  end

  defp create_new_villa(conn) do
    player = conn.assigns.current_player

    multi =
      Multi.new()
      |> Multi.insert(:villa, Villa.create_for(player))
      |> Multi.append(Player.recalc_points(player))

    case Repo.transaction(multi) do
      {:ok, %{villa: villa}} -> villa
      _ -> raise "Villa could not be created"
    end
  end

  defp load_villa(conn) do
    villa =
      load_villa_from_query_params(conn) ||
        load_villa_from_session(conn) ||
        load_first_villa(conn) ||
        create_new_villa(conn)

    if villa do
      villa = Repo.preload(villa, :unit_queue_items)

      conn
      |> assign(:current_villa, villa)
      |> put_session(:current_villa_id, villa.id)
    else
      conn
      |> delete_session(:current_villa_id)
    end
  end
end
