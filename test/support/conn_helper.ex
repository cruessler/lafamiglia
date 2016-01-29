defmodule LaFamiglia.ConnHelper do
  import ExUnit.Assertions
  import Phoenix.ConnTest

  @endpoint LaFamiglia.Endpoint

  def with_login(conn, player) do
    conn = post conn, "/session", [ session: [ email: player.email, password: "password" ]]

    assert html_response(conn, 302)
    assert redirected_to(conn)

    conn
  end
end
