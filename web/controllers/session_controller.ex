defmodule LaFamiglia.SessionController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Session

  plug :redirect_if_logged_in when not action in [ :delete ]

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => session_params}) do
    case Session.login(session_params) do
      { :ok, player } ->
        conn
        |> put_session(:current_player_id, player.id)
        |> put_flash(:info, "You are now logged in")
        |> redirect(to: Routes.villa_path(conn, :index))
      :error ->
        conn
        |> put_flash(:error, "Wrong email or password")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_player_id)
    |> put_flash(:info, "Logged out")
    |> redirect(to: Routes.page_path(conn, :index))
  end

  defp redirect_if_logged_in(conn, _) do
    if(conn.assigns[:current_player]) do
      conn |> redirect(to: Routes.page_path(conn, :index)) |> halt
    else
      conn
    end
  end
end
