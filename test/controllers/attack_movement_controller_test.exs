defmodule LaFamiglia.AttackMovementControllerTest do
  use LaFamiglia.ConnCase

  alias LaFamiglia.AttackMovement

  test "attack a villa" do
    origin = insert(:villa, %{unit_1: 1})
    target = insert(:villa)

    conn =
      build_conn()
      |> with_login(origin.player)
      |> get("/villas/#{origin.id}/attack_movements/new?target_id=#{target.id}")

    assert html_response(conn, 200) =~ target.name

    conn =
      post conn, "/villas/#{origin.id}/attack_movements", attack_movement: [target_id: target.id]

    assert html_response(conn, 200)

    conn =
      post conn, "/villas/#{origin.id}/attack_movements",
        attack_movement: [target_id: target.id, unit_1: 1]

    assert html_response(conn, 302)

    query =
      from(m in AttackMovement,
        where: m.origin_id == ^origin.id and m.target_id == ^target.id
      )

    assert Repo.all(query) |> Enum.count() == 1
  end
end
