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
        {:ok, _item} ->
          conn
          |> redirect(to: villa_path(conn, :show, villa_id))
      end
    end
  end
end
