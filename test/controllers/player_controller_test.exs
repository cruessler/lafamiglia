defmodule LaFamiglia.PlayerControllerTest do
  use LaFamiglia.ConnCase

  test "POST /players" do
    params = [player: [name: "New player",
                       email: "new@play.er",
                       password: "password",
                       password_confirmation: "password"]]

    conn = post conn(), "/players", params

    assert html_response(conn, 302)
  end
end
