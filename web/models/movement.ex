defmodule LaFamiglia.Movement do
  def units(map) do
    Enum.filter LaFamiglia.Unit.all, fn(u) ->
      Map.get(map, u.key) > 0
    end
  end

  defp speed(units) do
    speed =
      units
      |> Enum.map(fn(u) -> u.speed end)
      |> Enum.min

    speed / 3600 * Application.get_env(:la_famiglia, :unit_speed)
  end

  defp distance_between(origin, target) do
    :math.sqrt(:math.pow(origin.x - target.x, 2) + :math.pow(origin.y - target.y, 2))
  end

  @doc """
  This function returns the time the given units need to go from `origin` to
  `target` in seconds.

  The speed of a unit is given in coordinates per hour. A unit with a speed of 1
  will take 1 hour to go from 0|0 to 0|1.
  """
  def duration(origin, target, units) do
    distance_between(origin, target) / speed(units)
  end
end
