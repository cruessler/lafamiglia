defmodule LaFamiglia.BuildingQueueItemController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.BuildingQueueItem

  def create(conn, %{"building_id" => building_id}) do
    building = Building.get_by_id(String.to_integer(building_id))

    if building do
      case BuildingQueueItem.enqueue!(conn.assigns.current_villa_changeset, building) do
        {:error, changeset} ->
          [{_, message}|_] = changeset.errors

          conn
          |> put_flash(:info, message)
          |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
        {:ok, _villa} ->
          conn
          |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Repo.get_by!(BuildingQueueItem, id: id, villa_id: conn.assigns.current_villa.id)

    case BuildingQueueItem.dequeue!(conn.assigns.current_villa_changeset, item) do
      {:error, changeset} ->
        [{_, message}|_] = changeset.errors

        conn
        |> put_flash(:info, message)
        |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
      {:ok, _villa} ->
        conn
        |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end
end
