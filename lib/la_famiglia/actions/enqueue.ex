defmodule LaFamiglia.Actions.Enqueue do
  alias Ecto.Multi
  alias Ecto.Changeset

  alias LaFamiglia.{BuildingQueueItem, UnitQueueItem}

  def enqueue(%Changeset{} = changeset, %{points: _} = building) do
    Multi.new()
    |> Multi.update(:villa, BuildingQueueItem.enqueue(changeset, building))
    |> Multi.run(:send_to_queue, fn _repo, %{villa: villa} ->
      villa.building_queue_items
      |> List.last()
      |> LaFamiglia.EventCallbacks.send_to_queue()
    end)
  end

  def enqueue(%Changeset{} = changeset, %{attack: _} = unit, number) do
    Multi.new()
    |> Multi.update(:villa, UnitQueueItem.enqueue(changeset, unit, number))
    |> Multi.run(:send_to_queue, fn _repo, %{villa: villa} ->
      villa.unit_queue_items
      |> List.last()
      |> LaFamiglia.EventCallbacks.send_to_queue()
    end)
  end
end
