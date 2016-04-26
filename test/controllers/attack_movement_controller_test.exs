defmodule LaFamiglia.AttackMovementControllerTest do
  use LaFamiglia.ConnCase

  alias LaFamiglia.Villa
  alias LaFamiglia.AttackMovement

  setup do
    player = Forge.saved_player(Repo)
    origin =
      Villa.create_for(player)
      |> Ecto.Changeset.change
      |> Villa.add_units(%{unit_1: 1})
      |> Repo.update!
    conn   = conn |> with_login(player)

    enemy  = Forge.saved_player(Repo)
    target = Villa.create_for(enemy)

    {:ok, %{conn: conn, player: player, origin: origin, target: target}}
  end

  test "attack a villa", context do
    conn = get context.conn, "/villas/#{context.origin.id}/attack_movements/new?target_id=#{context.target.id}"
    assert html_response(conn, 200) =~ context.target.name

    conn = post conn, "/villas/#{context.origin.id}/attack_movements", [ attack_movement: [ target_id: context.target.id ]]
    assert html_response(conn, 200)

    conn = post conn, "/villas/#{context.origin.id}/attack_movements", [ attack_movement: [ target_id: context.target.id, unit_1: 1 ]]
    assert html_response(conn, 302)

    query = from m in AttackMovement,
              where: m.origin_id == ^context.origin.id
                and m.target_id == ^context.target.id
    assert Repo.all(query) |> Enum.count == 1
  end
end
