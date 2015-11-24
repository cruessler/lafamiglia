defprotocol LaFamiglia.Event do
  @fallback_to_any false
  @doc "Returns the time an event is supposed to happen"
  def happens_at(event)

  @doc "Handles an event"
  def handle(event)
end
