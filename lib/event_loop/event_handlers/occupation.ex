defimpl LaFamiglia.Event, for: LaFamiglia.Occupation do
  require Logger

  alias Ecto.Changeset
  alias Ecto.Multi

  alias LaFamiglia.Repo
  alias LaFamiglia.Player
  alias LaFamiglia.ComebackMovement
  alias LaFamiglia.ConquestReport

  def happens_at(occupation) do
    occupation.succeeds_at
  end

  def handle(occupation) do
    Logger.info("processing occupation event ##{occupation.id}")

    LaFamiglia.DateTime.clock!(occupation.succeeds_at)

    occupation = Repo.preload(occupation, origin: :player, target: :player)

    target_changeset =
      Changeset.change(occupation.target, %{is_occupied: false})
      |> Changeset.put_assoc(:player, occupation.origin.player)

    comeback = ComebackMovement.from_occupation(occupation)

    Multi.new()
    |> Multi.append(ConquestReport.deliver(occupation))
    |> Multi.delete(:occupation, occupation)
    |> Multi.update(:target, target_changeset)
    |> Multi.insert(:comeback, comeback)
    |> Multi.append(Player.recalc_points([occupation.origin.player, occupation.target.player]))
    |> Multi.run(:send_to_queue, fn _repo, %{comeback: comeback} ->
      LaFamiglia.EventQueue.cast({:new_event, comeback})

      {:ok, nil}
    end)
    |> Repo.transaction()
  end
end
