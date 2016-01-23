defmodule LaFamiglia.Movement do
  def units(map) do
    Enum.filter LaFamiglia.Unit.all, fn({_k, u}) ->
      Map.get(map, u.key) > 0
    end
  end

  @doc """
  This function returns the speed of an array of units in coordinates per
  second.

  The speed of a unit is given in coordinates per hour. A unit with a speed of 1
  will take 1 hour to go from 0|0 to 0|1.
  """
  defp speed(units) do
    speed =
      units
      |> Enum.map(fn({_k, u}) -> u.speed end)
      |> Enum.min

    speed / 3600
  end

  defp distance_between(origin, target) do
    :math.sqrt(:math.pow(origin.x - target.x, 2) + :math.pow(origin.y - target.y, 2))
  end

  def duration(origin, target, units) do
    distance_between(origin, target) / speed(units)
  end
end
