defmodule LaFamiglia.PlayerTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Player

  @valid_attrs %{ email: "mail@adre.ss", name: "some name",
                  points: 42, password: "this is a password" }
  @invalid_attrs %{ email: "not an email" }

  test "changeset with valid attributes" do
    changeset = Player.changeset(%Player{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Player.changeset(%Player{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "recalc_points" do
    player = insert(:player)
    insert_list(3, :villa, %{player: player})

    Player.recalc_points(player)
    |> Repo.transaction

    player = Repo.get(Player, player.id) |> Repo.preload(:villas)
    assert player.points == 3

    {:ok, player} = change(player) |> put_assoc(:villas, []) |> Repo.update

    Player.recalc_points(player)
    |> Repo.transaction

    player = Repo.get(Player, player.id)
    assert player.points == 0
  end
end
