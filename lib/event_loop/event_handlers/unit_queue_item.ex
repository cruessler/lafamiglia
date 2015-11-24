defimpl LaFamiglia.Event, for: LaFamiglia.UnitQueueItem do
  require Logger

  import Ecto.Model

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  def happens_at(item) do
    item.completed_at
  end

  def handle(item) do
    Logger.info "processing recruiting event ##{item.id}"

    unit  = Unit.get_by_id(item.unit_id)
    key   = unit.key
    villa = assoc(item, :villa) |> Repo.one

    changeset = Villa.changeset(villa, Map.put(%{}, key, Map.get(villa, key) + item.number))

    Repo.transaction fn ->
      Repo.update!(changeset)
      Repo.delete!(%UnitQueueItem{item | processed: true})
    end
  end
end
