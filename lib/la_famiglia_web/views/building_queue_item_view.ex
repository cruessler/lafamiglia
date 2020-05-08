defmodule LaFamigliaWeb.BuildingQueueItemView do
  use LaFamiglia.Web, :view

  def link_to_build_cancel(conn, item) do
    link("Cancel",
      to: Routes.building_queue_item_path(conn, :delete, item.id),
      method: :delete,
      class: "btn btn-primary"
    )
  end
end
