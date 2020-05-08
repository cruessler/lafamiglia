defmodule LaFamigliaWeb.SessionControllerTest do
  use LaFamigliaWeb.ConnCase

  test "GET /session/new" do
    conn = get(build_conn(), "/session/new")
    assert html_response(conn, 200) =~ "Log in"
  end
end
