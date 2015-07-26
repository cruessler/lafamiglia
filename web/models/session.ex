defmodule LaFamiglia.Session do
  alias LaFamiglia.Repo
  alias LaFamiglia.Player

  def current_player(conn) do
    id = Plug.Conn.get_session(conn, :current_player)
    if id, do: Repo.get(Player, id)
  end

  def player_logged_in?(conn), do: !!current_player(conn)

  def login(params) do
    player = Repo.get_by(Player, email: String.downcase(params["email"]))
    case authenticate(player, params["password"]) do
      true -> { :ok, player }
      _    -> :error
    end
  end

  defp authenticate(player, password) do
    case player do
      nil -> false
      _   -> Comeonin.Bcrypt.checkpw(password, player.hashed_password)
    end
  end
end
