defmodule LaFamiglia.VillaView do
  use LaFamiglia.Web, :view

  def link_to_build_start(conn, villa, building) do
    level = Building.level(villa, building)

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
end
