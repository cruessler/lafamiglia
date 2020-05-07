defmodule LaFamiglia.Actions.Dequeue do
  alias Ecto.Multi
  alias Ecto.Changeset

  alias LaFamiglia.{BuildingQueueItem, UnitQueueItem}

  def dequeue(%Changeset{} = changeset, %BuildingQueueItem{} = item) do
    Multi.new
    |> Multi.update(:villa, BuildingQueueItem.dequeue(changeset, item))
    |> Multi.run(:drop_from_queue, fn(_, _) ->
      LaFamiglia.EventCallbacks.drop_from_queue(item)
    end)
  end

  def dequeue(%Changeset{} = changeset, %UnitQueueItem{} = item) do
    Multi.new
    |> Multi.update(:villa, UnitQueueItem.dequeue(changeset, item))
    |> Multi.run(:drop_from_queue, fn(_, _) ->
      LaFamiglia.EventCallbacks.drop_from_queue(item)
    end)
  end
end
