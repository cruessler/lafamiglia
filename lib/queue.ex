defmodule LaFamiglia.Queue do
  def completed_at([]), do: LaFamiglia.DateTime.now
  def completed_at(queue) when is_list(queue), do: List.last(queue).completed_at

  @doc
  """
  Returns, in microseconds, how long it would take for an item in a queue to be
  completed.
  """
  def build_time_left([first|_], first),
    do: Timex.diff(LaFamiglia.DateTime.now, first.completed_at, :microseconds)
  def build_time_left(_, item), do: item.build_time

  @doc
  """
  Removes an item from a queue and shifts all later items’ completion time by
  `-time_diff`.

  Expects `time_diff` to be specified in microseconds.
  """
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
    new_completed_at = Timex.shift(item.completed_at, microseconds: -time_diff)

    Map.put(item, :completed_at, new_completed_at)
  end
end
