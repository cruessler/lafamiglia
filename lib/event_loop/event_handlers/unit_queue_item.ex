defimpl LaFamiglia.Event, for: LaFamiglia.UnitQueueItem do
  require Logger

  import Ecto
  import Ecto.Query

  alias Ecto.Changeset

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  def happens_at(item) do
    item.completed_at
  end

  def handle(item) do
    Logger.info "processing recruiting event ##{item.id}"

    unit  = Unit.get(item.unit_id)
    key   = unit.key
    villa = from(v in assoc(item, :villa), preload: :unit_queue_items) |> Repo.one

    changeset =
      villa
      |> Villa.changeset(%{key => Map.get(villa, key) + item.number})
      |> Changeset.put_change(:units_recruited_until, item.completed_at)

    Repo.transaction fn ->
      Repo.update!(changeset)
      Repo.delete!(item)
    end
  end
end
