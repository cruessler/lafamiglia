defmodule LaFamigliaWeb.BuildingQueueItemController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Building
  alias LaFamiglia.BuildingQueueItem

  def create(conn, %{"building_id" => building_id}) do
    building = Building.get(String.to_integer(building_id))
    changeset = BuildingQueueItem.enqueue(conn.assigns.current_villa_changeset, building)

    case Repo.update(changeset) do
      {:error, changeset, _} ->
        [{_, {message, _}} | _] = changeset.errors

        conn
        |> put_flash(:info, message)
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))

      {:ok, villa} ->
        villa.building_queue_items
        |> List.last()
        |> LaFamiglia.EventCallbacks.send_to_queue()

        conn
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Repo.get_by!(BuildingQueueItem, id: id, villa_id: conn.assigns.current_villa.id)
    changeset = BuildingQueueItem.dequeue(conn.assigns.current_villa_changeset, item)

    case Repo.update(changeset) do
      {:error, changeset} ->
        [{_, {message, _}} | _] = changeset.errors

        conn
        |> put_flash(:info, message)
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))

      {:ok, _villa} ->
        LaFamiglia.EventCallbacks.drop_from_queue(item)

        conn
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end
end
