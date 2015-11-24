defimpl LaFamiglia.Event, for: LaFamiglia.BuildingQueueItem do
  require Logger

  import Ecto.Model

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.BuildingQueueItem

  def happens_at(item) do
    item.completed_at
  end

  def handle(item) do
    Logger.info "processing build event ##{item.id}"

    building = Building.get_by_id(item.building_id)
    key      = building.key
    villa    = assoc(item, :villa) |> Repo.one

    changeset = Villa.changeset(villa, Map.put(%{}, key, Map.get(villa, key) + 1))

    Repo.transaction fn ->
      Repo.update!(changeset)
      Repo.delete!(%BuildingQueueItem{item | processed: true})
    end
  end
end
