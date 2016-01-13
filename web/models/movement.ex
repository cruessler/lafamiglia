defmodule LaFamiglia.Movement do
  def units(map) do
    Enum.filter LaFamiglia.Unit.all, fn({_k, u}) ->
      Map.get(map, u.key) > 0
    end
  end

  defp speed(units) do
    units
    |> Enum.map(fn({_k, u}) -> u.speed end)
    |> Enum.min
  end

  defp distance_between(origin, target) do
    :math.sqrt(:math.pow(origin.x - target.x, 2) + :math.pow(origin.y - target.y, 2))
  end

  def duration(origin, target, units) do
    distance_between(origin, target) / speed(units)
  end
end
