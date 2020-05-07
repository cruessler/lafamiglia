defmodule LaFamiglia.ReportControllerTest do
  use LaFamiglia.ConnCase

  alias LaFamiglia.Villa

  setup do
    player = insert(:player)
    conn = build_conn() |> with_login(player)

    {:ok, %{conn: conn, player: player}}
  end

  test "GET /reports", %{conn: conn} do
    conn = get(conn, "/reports")

    assert html_response(conn, 200) =~ "Reports"
  end

  test "GET /villas/1/reports", %{conn: conn, player: player} do
    villa = Villa.create_for(player) |> Repo.insert!()

    conn = get(conn, "/villas/#{villa.id}/reports")

    assert html_response(conn, 200) =~ "Reports"
  end

  test "GET /reports/1", %{conn: conn, player: player} do
    report = insert(:combat_report, %{player: player})

    conn = get(conn, "/reports/#{report.id}")

    assert html_response(conn, 200) =~ report.title

    report = insert(:conquest_report, %{player: player})

    conn = get(conn, "/reports/#{report.id}")

    assert html_response(conn, 200) =~ report.title
  end
end
