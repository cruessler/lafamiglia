defmodule LaFamiglia.ReportTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.{Combat, CombatReport}
  alias LaFamiglia.Report
  alias LaFamiglia.ReportData

  @valid_attrs %{title: "This is a title",
                 data: %ReportData{winner: :attacker},
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
    LaFamiglia.DateTime.clock!

    attack =
      Forge.saved_attack_movement(Repo)
      |> Repo.preload([origin: [:player], target: [:player]])

    {:ok, %{
        origin: attack.origin,
        target: attack.target,
        result: Combat.calculate(attack, attack.target)}}
  end

  defp reports_count(player) do
    from(r in Ecto.assoc(player, :reports), select: count(r.id)) |> Repo.one
  end

  test "gets gelivered", context do
    old_reports_count = reports_count(context.origin.player)

    CombatReport.deliver!(context.origin, context.target, context.result)

    assert reports_count(context.origin.player) == old_reports_count + 1
  end

  test "has associations", context do
    CombatReport.deliver!(context.origin, context.target, context.result)

    [first, second] =
      from(r in Report, order_by: [desc: r.id], limit: 2, preload: :player)
      |> Repo.all

    assert second.player.id == context.origin.player.id
    assert first.player.id  == context.target.player.id
  end

  test "has related villas", context do
    CombatReport.deliver!(context.origin, context.target, context.result)

    report =
      from(r in Report, order_by: [desc: r.id], limit: 1, preload: :related_villas)
      |> Repo.one

    [first, second] = report.related_villas

    assert second.id == context.target.id
    assert first.id  == context.origin.id
  end

  test "has title", context do
    CombatReport.deliver!(context.origin, context.target, context.result)

    [first, second] =
      from(r in Report, order_by: [desc: r.id], limit: 2)
      |> Repo.all

    assert first.title  == "Attack from #{context.origin}"
    assert second.title == "Attack on #{context.target}"
  end
end
