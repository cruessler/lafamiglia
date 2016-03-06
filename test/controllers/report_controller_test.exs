defmodule LaFamiglia.ReportControllerTest do
  use LaFamiglia.ConnCase

  setup do
    player = Forge.saved_player(Repo)
    conn   = conn |> with_login(player)

    {:ok, %{conn: conn, player: player}}
  end

  test "GET /reports", %{conn: conn} do
    conn = get conn, "/reports"

    assert html_response(conn, 200) =~ "Reports"
  end

  test "GET /reports/1", %{conn: conn, player: player} do
    report = Forge.saved_report(Repo, player_id: player.id)

    conn = get conn, "/reports/#{report.id}"

    assert html_response(conn, 200) =~ report.title
  end
end
