defmodule LaFamiglia.BuildingQueueItemController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Building
  alias LaFamiglia.BuildingQueueItem
  alias LaFamiglia.Actions.{Enqueue, Dequeue}

  def create(conn, %{"building_id" => building_id}) do
    building = Building.get(String.to_integer(building_id))
    multi    = Enqueue.enqueue(conn.assigns.current_villa_changeset, building)

    case Repo.transaction(multi) do
      {:error, :villa, changeset, _} ->
        [{_, message}|_] = changeset.errors

        conn
        |> put_flash(:info, message)
        |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
      {:ok, _villa} ->
        conn
        |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end

  def delete(conn, %{"id" => id}) do
    item  = Repo.get_by!(BuildingQueueItem, id: id, villa_id: conn.assigns.current_villa.id)
    multi = Dequeue.dequeue(conn.assigns.current_villa_changeset, item)

    case Repo.transaction(multi) do
      {:error, :villa, changeset} ->
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
