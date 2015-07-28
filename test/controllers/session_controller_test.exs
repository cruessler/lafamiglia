defmodule LaFamiglia.SessionControllerTest do
  use LaFamiglia.ConnCase

  test "GET /session/new" do
    conn = get conn(), "/session/new"
    assert html_response(conn, 200) =~ "Log in"
  end
end
