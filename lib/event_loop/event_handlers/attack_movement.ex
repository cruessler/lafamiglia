defimpl LaFamiglia.Event, for: LaFamiglia.AttackMovement do
  require Logger

  alias LaFamiglia.Repo
  alias LaFamiglia.Combat
  alias LaFamiglia.AttackMovement
  alias LaFamiglia.CombatReport

  def happens_at(movement) do
    movement.arrives_at
  end

  def handle(attack) do
    Logger.info "processing attack event ##{attack.id}"

    LaFamiglia.DateTime.clock!

    # `target` has to be dropped from `model` because it would still be present
    # when the event is sent to the queue by the respective controller action.
    # In that case, the preloading of `target.player` would not work when the
    # event is handled.
    attack =
      Repo.get(AttackMovement, attack.id)
      |> Repo.preload([target: :player, origin: :player])
    result = Combat.calculate(attack, attack.target)

    Repo.transaction fn ->
      CombatReport.deliver!(attack.origin, attack.target, result)

      {:ok, comeback} = AttackMovement.cancel!(attack)

      LaFamiglia.EventQueue.cast({:new_event, comeback})
    end
  end
end
