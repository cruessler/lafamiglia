defmodule LaFamiglia.OccupationTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Repo

  alias LaFamiglia.Combat
  alias LaFamiglia.Occupation

  setup do
    LaFamiglia.DateTime.clock!

    attack =
      Forge.saved_attack_movement(Repo)
      |> Repo.preload(target: [:player, :unit_queue_items], origin: :player)

    combat = Combat.new(attack) |> Combat.calculate

    {:ok, %{combat: combat}}
  end

  test "from_combat", context do
    multi = Occupation.from_combat(context.combat)

    assert {:ok, %{occupation: occupation}} = Repo.transaction(multi)

    target = Repo.get!(Villa, occupation.target.id)
    assert target.is_occupied
  end
end
