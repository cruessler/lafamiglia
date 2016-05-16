defimpl LaFamiglia.Event, for: LaFamiglia.AttackMovement do
  require Logger

  alias Ecto.Changeset
  alias Ecto.Multi

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

    %{target_changeset: target_changeset, result: result} =
      Combat.new(attack)
      |> Combat.calculate

    origin_changeset =
      Changeset.change(attack.origin)
      |> Villa.subtract_supply(result.attacker_supply_loss)
    target_changeset =
      target_changeset
      |> Villa.subtract_units(result.defender_losses)
      |> Villa.subtract_supply(result.defender_supply_loss)
      |> Villa.subtract_resources(result.resources_plundered)

    multi =
      Multi.new
      |> Multi.run(:deliver_report, fn(_) ->
        CombatReport.deliver!(attack.origin, attack.target, result)

        {:ok, nil}
      end)
      |> Multi.delete(:attack, attack)
      |> Multi.update(:origin, origin_changeset)
      |> Multi.update(:target, target_changeset)

    multi =
      if result.attacker_survived? do
        changeset = ComebackMovement.from_combat(attack, result)

        multi
        |> Multi.insert(:comeback, changeset)
        |> Multi.run(:send_to_queue, fn(%{comeback: comeback}) ->
          LaFamiglia.EventQueue.cast({:new_event, comeback})

          {:ok, nil}
        end)
      else
        multi
      end

    Repo.transaction(multi)
  end
end
