defmodule LaFamiglia.VillaView do
  use LaFamiglia.Web, :view

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

  def link_to_build_cancel(conn, item) do
    link "Cancel", to: building_queue_item_path(conn, :delete, item.id),
                       method: :delete, class: "btn btn-primary"
  end

  def link_to_recruit_start(conn, villa, unit, number) do
    link Integer.to_string(number),
         to: villa_unit_queue_item_path(conn, :create, villa.id, [unit_id: unit.id, number: number]),
         method: :post, class: "btn btn-primary btn-sm"
  end

  def link_to_recruit_cancel(conn, item) do
    link "Cancel", to: unit_queue_item_path(conn, :delete, item.id),
                       method: :delete, class: "btn btn-primary"
  end
end
