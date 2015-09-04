defmodule LaFamiglia.UnitQueueItemController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Unit
  alias LaFamiglia.UnitQueueItem

  def create(conn, %{"villa_id" => villa_id, "unit_id" => unit_id, "number" => number}) do
    unit   = Unit.get_by_id(String.to_integer(unit_id))
    number = String.to_integer(number)

    if unit do
      case UnitQueueItem.enqueue!(conn.assigns.current_villa_untouched, unit, number) do
        {:error, message} ->
          conn
          |> put_flash(:info, message)
          |> redirect(to: villa_path(conn, :show, villa_id))
        {:ok, item} ->
          LaFamiglia.EventQueue.cast({:new_event, item})

          conn
          |> redirect(to: villa_path(conn, :show, villa_id))
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Repo.get_by!(UnitQueueItem, id: id, villa_id: conn.assigns.current_villa.id)

    {:ok, item} = UnitQueueItem.dequeue!(conn.assigns.current_villa, item)

    LaFamiglia.EventQueue.cast({:cancel_event, item})

    conn
    |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
  end
end
