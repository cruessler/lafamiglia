defmodule LaFamiglia.Queue do
  def completed_at([]) do
    LaFamiglia.DateTime.now
  end
  def completed_at(queue) when is_list(queue) do
    List.last(queue).completed_at
  end

  def build_time_left(queue_items, item) do
    case List.first(queue_items) do
      ^item ->
        LaFamiglia.DateTime.time_diff(LaFamiglia.DateTime.now, item.completed_at)
      _ ->
        item.build_time
    end
  end

  def remove_item(queue_items, item) do
    Enum.filter queue_items, fn(i) -> i != item end
  end

  def shift_later_items(queue_items, item, time_diff) do
    Enum.map queue_items, fn(other_item) ->
      case Ecto.DateTime.compare(other_item.completed_at, item.completed_at) do
        :gt ->
          new_completed_at = LaFamiglia.DateTime.add_seconds(other_item.completed_at, -time_diff)

          Map.put(other_item, :completed_at, new_completed_at)
        _ ->
          other_item
      end
    end
  end
end
