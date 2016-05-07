defimpl LaFamiglia.Event, for: LaFamiglia.AttackMovement do
  require Logger

  alias Ecto.Changeset

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.Combat
  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement
  alias LaFamiglia.CombatReport

  def happens_at(movement) do
    movement.arrives_at
  end

  def handle(attack) do
    Logger.info "processing attack event ##{attack.id}"

    LaFamiglia.DateTime.clock!(attack.arrives_at)

    attack = Repo.preload(attack, target: [:player, :unit_queue_items], origin: :player)
    target_changeset =
      Changeset.change(attack.target)
      |> Villa.process_virtually_until(attack.arrives_at)

    result = Combat.calculate(attack, Changeset.apply_changes(target_changeset))

    origin_changeset =
      Changeset.change(attack.origin)
      |> Villa.subtract_supply(result.attacker_supply_loss)
    target_changeset =
      target_changeset
      |> Villa.subtract_units(result.defender_losses)
      |> Villa.subtract_supply(result.defender_supply_loss)
      |> Villa.subtract_resources(result.resources_plundered)

    Repo.transaction fn ->
      CombatReport.deliver!(attack.origin, attack.target, result)
      Repo.delete(attack)
      Repo.update!(origin_changeset)
      Repo.update!(target_changeset)

      if result.attacker_survived? do
        changeset = ComebackMovement.from_combat(attack, result)

        {:ok, comeback} = Repo.insert(changeset)
        LaFamiglia.EventQueue.cast({:new_event, comeback})
      end
    end
  end
end
