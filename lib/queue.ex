defmodule LaFamiglia.Queue do
  def completed_at([]), do: LaFamiglia.DateTime.now
  def completed_at(queue) when is_list(queue), do: List.last(queue).completed_at

  def build_time_left([first|rest], first),
    do: LaFamiglia.DateTime.time_diff(LaFamiglia.DateTime.now, first.completed_at)
  def build_time_left(_, item), do: item.build_time

  def shift_later_items([item], item, time_diff), do: []
  def shift_later_items([item|rest], item, time_diff),
    do: shift_items(rest, time_diff)
  def shift_later_items([first|rest], item, time_diff),
    do: [first] ++ shift_later_items(rest, item, time_diff)

  def shift_items([], _), do: []
  def shift_items([first|rest], time_diff),
    do: [shift_item(first, time_diff)|shift_items(rest, time_diff)]

  defp shift_item(item, time_diff) do
    new_completed_at = LaFamiglia.DateTime.add_seconds(item.completed_at, -time_diff)

    Map.put(item, :completed_at, new_completed_at)
  end
end
