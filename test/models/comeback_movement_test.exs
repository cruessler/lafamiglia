defmodule LaFamiglia.ComebackMovementTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Resource

  setup do
    LaFamiglia.DateTime.clock!

    :ok
  end

  test "gets handled" do
    comeback = insert(:comeback)

    assert LaFamiglia.Event.handle(comeback)

    origin = Repo.get(Villa, comeback.origin.id)
    assert Resource.filter(origin) != Resource.filter(comeback.origin)
    assert origin.resource_1 == comeback.origin.resource_1 + comeback.resource_1
  end
end
