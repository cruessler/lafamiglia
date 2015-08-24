defmodule LaFamiglia.BuildingQueueItemController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.BuildingQueueItem

  def create(conn, %{"villa_id" => villa_id, "building_id" => building_id}) do
    building = Building.get_by_id(String.to_integer(building_id))

    if building do
      case BuildingQueueItem.enqueue(conn.assigns.current_villa, building) do
        {:error, changeset} ->
          conn
          |> put_flash(:alert, changeset.errors[:building_queue_items])
          |> redirect(to: villa_path(conn, :show, villa_id))
        {:ok, _item} ->
          conn
          |> redirect(to: villa_path(conn, :show, villa_id))
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Repo.get_by!(BuildingQueueItem, id: id, villa_id: conn.assigns.current_villa.id)

    BuildingQueueItem.dequeue(conn.assigns.current_villa, item)

    conn
    |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
  end
end
