defimpl LaFamiglia.Event, for: LaFamiglia.AttackMovement do
  require Logger

  alias Ecto.Changeset

  alias LaFamiglia.Repo
  alias LaFamiglia.Combat
  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement
  alias LaFamiglia.CombatReport

  def happens_at(movement) do
    movement.arrives_at
  end

  def handle(attack) do
    Logger.info "processing attack event ##{attack.id}"

    LaFamiglia.DateTime.clock!

    # `attack` is reloaded because its associations might have changed since
    # the event’s creation.
    attack =
      Repo.get(AttackMovement, attack.id)
      |> Repo.preload([target: :player, origin: :player])
    result = Combat.calculate(attack, attack.target)

    origin_changeset =
      Changeset.change(attack.origin)
      |> Changeset.put_change(:supply, result.attacker_supply_loss)

    Repo.transaction fn ->
      CombatReport.deliver!(attack.origin, attack.target, result)
      Repo.delete(attack)
      Repo.update!(origin_changeset)

      if result.attacker_survived? do
        changeset = ComebackMovement.from_combat(attack, result)

        {:ok, comeback} = Repo.insert(changeset)
        LaFamiglia.EventQueue.cast({:new_event, comeback})
      end
    end
  end
end
