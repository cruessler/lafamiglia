defmodule LaFamiglia.VillaControllerTest do
  use LaFamiglia.ConnCase

  alias LaFamiglia.Player
  alias LaFamiglia.Villa

  setup do
    player = insert(:player)
    conn = build_conn() |> with_login(player)

    {:ok, %{conn: conn, player: player}}
  end

  test "GET /villas", %{conn: conn, player: player} do
    conn = get(conn, "/villas")

    player = from(p in Player, preload: :villas) |> Repo.get(player.id)
    villa = hd(player.villas)

    assert Enum.count(player.villas) == 1
    assert player.points == villa.points
    assert html_response(conn, 200) =~ "at your service"
    assert html_response(conn, 200) =~ villa.name
  end

  test "GET /villas/1", %{conn: conn, player: player} do
    villa = Villa.create_for(player) |> Repo.insert!()

    conn = get(conn, "/villas/#{villa.id}")

    assert html_response(conn, 200) =~ "The villa bearing the name"
    assert html_response(conn, 200) =~ "<a href=\"/villas/#{villa.id}\">"
  end

  test "GET /villas/1 does not show wrong villa", %{conn: conn} do
    villa = insert(:villa)

    conn = get(conn, "/villas/#{villa.id}")

    assert html_response(conn, 200) =~ "The villa bearing the name"
    refute html_response(conn, 200) =~ "<a href=\"/villas/#{villa.id}\">"
  end
end
