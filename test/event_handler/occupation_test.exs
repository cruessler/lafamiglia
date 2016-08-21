defmodule LaFamiglia.EventHandler.OccupationTest do
  use LaFamiglia.EventHandlerCase

  alias LaFamiglia.Player

  test "gets handled" do
    occupation = insert(:occupation)

    assert occupation.target.is_occupied

    assert {:ok, _} = LaFamiglia.Event.handle(occupation)

    target = Repo.get(Villa, occupation.target.id) |> Repo.preload(:player)

    assert target.player_id == occupation.origin.player_id
    assert occupation.origin.player.points < target.player.points
    assert target.player.points == 2
    refute target.is_occupied

    previous_owner = Repo.get(Player, occupation.target.player.id)

    assert occupation.target.player.points > previous_owner.points
    assert previous_owner.points == 0
  end
end
