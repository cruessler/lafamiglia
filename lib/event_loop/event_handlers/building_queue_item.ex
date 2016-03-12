defimpl LaFamiglia.Event, for: LaFamiglia.BuildingQueueItem do
  require Logger

  import Ecto.Model
  import Ecto.Query, only: [from: 2]

  alias LaFamiglia.Building

  alias LaFamiglia.Repo
  alias LaFamiglia.Player
  alias LaFamiglia.Villa
  alias LaFamiglia.BuildingQueueItem

  def happens_at(item) do
    item.completed_at
  end

  def handle(item) do
    Logger.info "processing build event ##{item.id}"

    building = Building.get(item.building_id)
    key      = building.key
    villa =
      from(v in assoc(item, :villa),
        preload: [:player, :unit_queue_items])
      |> Repo.one

    changeset =
      villa
      |> Villa.changeset(%{key => Map.get(villa, key) + 1})
      |> Villa.recalc_points
      |> Villa.process_virtually_until(item.completed_at)

    Repo.transaction fn ->
      Repo.update!(changeset)
      Repo.delete!(%BuildingQueueItem{item | processed: true})

      Player.recalc_points!(villa.player)
    end
  end
end
