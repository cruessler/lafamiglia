defimpl LaFamiglia.Event, for: LaFamiglia.BuildingQueueItem do
  require Logger

  import Ecto
  import Ecto.Query, only: [from: 2]

  alias Ecto.Changeset

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
      |> Changeset.change
      |> Villa.gain_resources_until(item.completed_at)
      |> Changeset.put_change(key, Map.get(villa, key) + 1)
      |> Villa.recalc_points
      |> Villa.recalc_storage_capacity
      |> Villa.recalc_max_supply

    Repo.transaction fn ->
      Repo.update!(changeset)
      Repo.delete!(item)

      Player.recalc_points!(villa.player)
    end
  end
end
