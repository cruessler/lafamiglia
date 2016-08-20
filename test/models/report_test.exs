defmodule LaFamiglia.ReportTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Combat
  alias LaFamiglia.Report
  alias LaFamiglia.CombatReport

  @valid_attrs %{title: "This is a title",
                 player_id: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Report.changeset(%Report{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Report.changeset(%Report{}, @invalid_attrs)
    refute changeset.valid?
  end

  setup do
    attack = build(:attack)

    [report_for_origin: {:insert, first, []}, report_for_target: {:insert, second, []}] =
      attack
      |> Combat.new
      |> Combat.calculate
      |> CombatReport.deliver
      |> Ecto.Multi.to_list

    {:ok, %{attack: attack, first: first, second: second}}
  end

  test "is valid", %{attack: attack, first: first, second: second} do
    assert first.valid?
    assert second.valid?

    assert get_change(first, :title) == "Attack on #{attack.target}"
    assert get_change(second, :title) == "Attack from #{attack.origin}"
  end

  test "has associations", %{attack: attack, first: first} do
    [first_related, second_related] = get_change(first, :related_villas)

    assert get_field(first_related, :player) == attack.origin.player
    assert get_field(second_related, :player) == attack.target.player

    assert second_related.data == attack.target
    assert first_related.data == attack.origin
  end

  test "can be deleted" do
    report = insert(:combat_report)

    assert {:ok, _} = Repo.delete(report)
  end
end
