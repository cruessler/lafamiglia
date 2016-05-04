defmodule LaFamiglia.Combat.AfterCombat do
  alias LaFamiglia.Resource

  @doc """
  This function determines how much of each resource can be plundered if the
  total amount is given and the resources are plundered evenly.

  It returns a map whose values are integers.
  """
  def plunder(resources_remaining, load_remaining) do
    remaining_total = for({_, n} <- resources_remaining, do: n) |> Enum.sum

    if remaining_total >= 1 && load_remaining > 0 do
      plunderable_per_resource = max(min(load_remaining, remaining_total) / Resource.count, 1)

      to_plunder =
        Map.new(resources_remaining, fn({k, n}) -> {k, trunc(min(plunderable_per_resource, n))} end)

      resources_remaining =
        Map.merge(resources_remaining, to_plunder, fn(_, v1, v2) -> v1 - v2 end)
      load_remaining =
        Enum.reduce(to_plunder, load_remaining, fn({_k, n}, acc) -> acc - n end)

      plunder(resources_remaining, load_remaining)
      |> Map.merge(to_plunder, fn(_k, v1, v2) -> v1 + v2 end)
    else
      %{resource_1: 0, resource_2: 0, resource_3: 0}
    end
  end
end
