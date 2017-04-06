defmodule LaFamiglia.Queue do
  def completed_at([]), do: LaFamiglia.DateTime.now
  def completed_at(queue) when is_list(queue), do: List.last(queue).completed_at

  def build_time_left([first|_], first),
    do: LaFamiglia.DateTime.time_diff(LaFamiglia.DateTime.now, first.completed_at)
  def build_time_left(_, item), do: item.build_time

  def shift_later_items([first|rest], item, time_diff) do
    cond do
      first.id == item.id -> shift_items(rest, time_diff)
      true -> [first] ++ shift_later_items(rest, item, time_diff)
    end
  end

  def shift_items(items, time_diff) do
    for item <- items, do: shift_item(item, time_diff)
  end

  defp shift_item(item, time_diff) do
    new_completed_at = LaFamiglia.DateTime.add_seconds(item.completed_at, -time_diff)

    Map.put(item, :completed_at, new_completed_at)
  end
end
