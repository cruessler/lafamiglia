defimpl LaFamiglia.Event, for: LaFamiglia.AttackMovement do
  require Logger

  alias LaFamiglia.Repo
  alias LaFamiglia.Combat

  def happens_at(movement) do
    movement.arrives_at
  end

  def handle(attack) do
    Logger.info "processing attack event ##{attack.id}"

    LaFamiglia.DateTime.clock!(attack.arrives_at)

    attack = Repo.preload(attack, target: [:player, :unit_queue_items], origin: :player)

    Combat.new(attack)
    |> Combat.calculate
    |> Combat.to_multi
    |> Repo.transaction
  end
end
