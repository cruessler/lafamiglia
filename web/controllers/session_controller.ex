defmodule LaFamiglia.SessionController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Session

  plug :authenticate when not action in [ :delete ]

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => session_params}) do
    case Session.login(session_params) do
      { :ok, player } ->
        conn
        |> put_session(:current_player, player.id)
        |> put_flash(:info, "You are now logged in")
        |> redirect(to: page_path(conn, :index))
      :error ->
        conn
        |> put_flash(:error, "Wrong email or password")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_player)
    |> put_flash(:info, "Logged out")
    |> redirect(to: page_path(conn, :index))
  end

  defp authenticate(conn, _) do
    if(Session.player_logged_in?(conn)) do
      conn |> redirect(to: page_path(conn, :index)) |> halt
    else
      conn
    end
  end
end
