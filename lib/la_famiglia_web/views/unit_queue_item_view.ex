defmodule LaFamigliaWeb.UnitQueueItemView do
  use LaFamiglia.Web, :view

  def link_to_recruit_cancel(conn, item) do
    link("Cancel",
      to: Routes.unit_queue_item_path(conn, :delete, item.id),
      method: :delete,
      class: "btn btn-primary"
    )
  end
end
