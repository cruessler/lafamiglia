defmodule LaFamiglia.Resource do
  @resources [:resource_1, :resource_2, :resource_3]

  def all, do: @resources

  def count, do: Enum.count(@resources)

  def filter(map) when is_map(map) do
    all
    |> Map.new(fn(k) -> {k, Map.get(map, k)} end)
  end
end
