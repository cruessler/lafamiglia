defmodule LaFamiglia.SessionControllerTest do
  use LaFamiglia.ConnCase

  test "GET /sessions/new" do
    conn = get conn(), "/sessions/new"
    assert html_response(conn, 200) =~ "Log in"
  end
end
