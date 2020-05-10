defmodule LaFamigliaWeb.UnitQueueItemController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  def create(conn, %{"villa_id" => villa_id, "unit_id" => unit_id, "number" => number}) do
    unit = Unit.get(String.to_integer(unit_id))
    number = String.to_integer(number)
    changeset = UnitQueueItem.enqueue(conn.assigns.current_villa_changeset, unit, number)

    case Repo.update(changeset) do
      {:error, changeset} ->
        [{_, {message, _}} | _] = changeset.errors

        conn
        |> put_flash(:info, message)
        |> redirect(to: Routes.villa_path(conn, :show, villa_id))

      {:ok, villa} ->
        villa.unit_queue_items
        |> List.last()
        |> LaFamiglia.EventCallbacks.send_to_queue()

        conn
        |> redirect(to: Routes.villa_path(conn, :show, villa_id))
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Repo.get_by!(UnitQueueItem, id: id, villa_id: conn.assigns.current_villa.id)
    changeset = UnitQueueItem.dequeue(conn.assigns.current_villa_changeset, item)

    case Repo.update(changeset) do
      {:error, changeset} ->
        [{_, {message, _}} | _] = changeset.errors

        conn
        |> put_flash(:info, message)
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))

      {:ok, villa} ->
        LaFamiglia.EventCallbacks.drop_from_queue(item)

        conn
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end
end
