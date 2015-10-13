defprotocol LaFamiglia.Event do
  @fallback_to_any false
  @doc "Returns the time an event is supposed to happen"
  def happens_at(event)
end

defimpl LaFamiglia.Event, for: [LaFamiglia.AttackMovement, LaFamiglia.ComebackMovement] do
  def happens_at(movement) do
    movement.arrives_at
  end
end

defimpl LaFamiglia.Event, for: [LaFamiglia.BuildingQueueItem, LaFamiglia.UnitQueueItem] do
  def happens_at(item) do
    item.completed_at
  end
end
