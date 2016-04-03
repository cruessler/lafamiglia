defimpl LaFamiglia.Event, for: LaFamiglia.ComebackMovement do
  require Logger

  alias LaFamiglia.ComebackMovement

  def happens_at(movement) do
    movement.arrives_at
  end

  def handle(comeback) do
    Logger.info "processing comeback event ##{comeback.id}"

    LaFamiglia.DateTime.clock!(comeback.arrives_at)

    ComebackMovement.arrive!(comeback)
  end
end
