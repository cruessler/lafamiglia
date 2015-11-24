defimpl LaFamiglia.Event, for: LaFamiglia.AttackMovement do
  require Logger

  alias LaFamiglia.AttackMovement

  def happens_at(movement) do
    movement.arrives_at
  end

  def handle(attack) do
    Logger.info "processing attack event ##{attack.id}"

    LaFamiglia.DateTime.clock!

    {:ok, comeback} = AttackMovement.cancel!(attack)
    LaFamiglia.EventQueue.cast({:new_event, comeback})
  end
end
