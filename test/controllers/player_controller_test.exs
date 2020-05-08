defmodule LaFamigliaWeb.PlayerControllerTest do
  use LaFamigliaWeb.ConnCase

  test "POST /players" do
    params = [
      player: [
        name: "New player",
        email: "new@play.er",
        password: "password",
        password_confirmation: "password"
      ]
    ]

    conn = post build_conn(), "/players", params

    assert html_response(conn, 302)
  end
end
