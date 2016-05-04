defmodule LaFamiglia.ComebackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Resource

  setup do
    LaFamiglia.DateTime.clock!

    comeback =
      Forge.saved_comeback_movement(Repo)
      |> Repo.preload(origin: :player, target: :player)

    {:ok, %{comeback: comeback}}
  end

  test "gets handled", %{comeback: comeback} do
    assert LaFamiglia.Event.handle(comeback)

    origin = Repo.get(Villa, comeback.origin.id)
    assert Resource.filter(origin) != Resource.filter(comeback.origin)
    assert origin.resource_1 == comeback.origin.resource_1 + comeback.resource_1
  end
end
