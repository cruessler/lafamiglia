defmodule LaFamiglia.UnitQueueItemController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem
  alias LaFamiglia.Actions.{Enqueue, Dequeue}

  def create(conn, %{"villa_id" => villa_id, "unit_id" => unit_id, "number" => number}) do
    unit   = Unit.get(String.to_integer(unit_id))
    number = String.to_integer(number)
    multi  = Enqueue.enqueue(conn.assigns.current_villa_changeset, unit, number)

    case Repo.transaction(multi) do
      {:error, :villa, changeset} ->
        [{_, message}|_] = changeset.errors

        conn
        |> put_flash(:info, message)
        |> redirect(to: Routes.villa_path(conn, :show, villa_id))
      {:ok, _villa} ->
        conn
        |> redirect(to: Routes.villa_path(conn, :show, villa_id))
    end
  end

  def delete(conn, %{"id" => id}) do
    item  = Repo.get_by!(UnitQueueItem, id: id, villa_id: conn.assigns.current_villa.id)
    multi = Dequeue.dequeue(conn.assigns.current_villa_changeset, item)

    case Repo.transaction(multi) do
      {:error, :villa, changeset} ->
        [{_, message}|_] = changeset.errors

        conn
        |> put_flash(:info, message)
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))
      {:ok, _villa} ->
        conn
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end
end
