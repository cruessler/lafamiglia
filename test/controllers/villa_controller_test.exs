defmodule LaFamiglia.VillaControllerTest do
  use LaFamiglia.ConnCase

  alias LaFamiglia.Player
  alias LaFamiglia.Villa

  test "GET /villas" do
    changeset = Player.changeset(%Player{}, %{name: "Name", email: "e@ma.il", password: "password", password_confirmation: "password"})
    player = Repo.insert!(changeset)

    conn = post conn(), "/session", [ session: [ email: player.email, password: "password" ]]
    assert html_response(conn, 302)
    assert redirected_to(conn)

    conn = get conn, "/villas"
    assert html_response(conn, 200) =~ "at your service"
  end

  test "GET /villas/1" do
    changeset = Player.changeset(%Player{}, %{name: "Name", email: "e@ma.il", password: "password", password_confirmation: "password"})
    player = Repo.insert!(changeset)
    villa  = Villa.create_for player

    conn = post conn(), "/session", [ session: [ email: player.email, password: "password" ]]
    assert html_response(conn, 302)
    assert redirected_to(conn)

    conn = get conn, "/villas/#{villa.id}"

    html_response(conn, 200) =~ "The villa bearing the name"
  end
end
