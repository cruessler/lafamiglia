defmodule LaFamiglia.PageControllerTest do
  use LaFamiglia.ConnCase

  test "GET /" do
    conn = get conn(), "/"
    assert html_response(conn, 200) =~ "you will find a landing page"
  end
end
