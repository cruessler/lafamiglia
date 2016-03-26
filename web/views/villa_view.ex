defmodule LaFamiglia.VillaView do
  use LaFamiglia.Web, :view

  alias LaFamiglia.BuildingQueueItemView

  def link_to_build_start(conn, villa, building) do
    level = Building.virtual_level(villa, building)

    if level < building.maxlevel do
      title = if level > 0 do
        "Upgrade"
      else
        "Build"
      end

      link title, to: villa_building_queue_item_path(conn, :create, villa.id, building_id: building.id),
                  method: :post, class: "btn btn-primary"
    else
      link "Maximum level", to: "#", class: "btn btn-primary disabled"
    end
  end

  def link_to_recruit_start(conn, villa, unit, number) do
    if Villa.has_supply?(villa, unit.supply * number) do
      link Integer.to_string(number),
           to: villa_unit_queue_item_path(conn, :create, villa.id, [unit_id: unit.id, number: number]),
           method: :post, class: "btn btn-primary btn-sm"
    else
      link Integer.to_string(number), to: "#", class: "btn btn-primary btn-sm disabled"
    end
  end

  def link_to_recruit_cancel(conn, item) do
    link "Cancel", to: unit_queue_item_path(conn, :delete, item.id),
                       method: :delete, class: "btn btn-primary"
  end

  def building_queue_items_for(conn, [], _), do: ""
  def building_queue_items_for(conn, [first|rest], building) do
    if first.building_id == building.id do
      [active_queue_item(conn, BuildingQueueItemView, first),
       waiting_queue_items(conn, BuildingQueueItemView, rest, building: building)]
    else
      waiting_queue_items(conn, BuildingQueueItemView, rest, building: building)
    end
  end

  defp active_queue_item(conn, module, item) do
    render module, "_active.html", conn: conn, item: item
  end

  defp waiting_queue_items(conn, module, queue, args) do
    render module, "_waiting.html", Keyword.merge(args, conn: conn, queue: queue)
  end
end
