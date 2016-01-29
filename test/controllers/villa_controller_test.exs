defmodule LaFamiglia.VillaControllerTest do
  use LaFamiglia.ConnCase

  alias LaFamiglia.Villa

  defp with_login(conn, player) do
    conn = post conn, "/session", [ session: [ email: player.email, password: "password" ]]

    assert html_response(conn, 302)
    assert redirected_to(conn)

    conn
  end

  setup do
    player = Forge.saved_player(Repo)
    conn   = conn |> with_login(player)

    {:ok, %{conn: conn, player: player}}
  end

  test "GET /villas", %{conn: conn} do
    conn = get conn, "/villas"

    assert html_response(conn, 200) =~ "at your service"
  end

  test "GET /villas/1", %{conn: conn, player: player} do
    villa  = Villa.create_for player

    conn = get conn, "/villas/#{villa.id}"

    html_response(conn, 200) =~ "The villa bearing the name"
  end
end
