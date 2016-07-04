defmodule LaFamiglia.Resource do
  import Ecto.Changeset
  alias Ecto.Changeset

  @resources [:resource_1, :resource_2, :resource_3]

  def all, do: @resources

  def count, do: Enum.count(@resources)

  def filter(%Changeset{} = changeset),
    do: for r <- all, into: %{}, do: {r, get_field(changeset, r)}
  def filter(map),
    do: for r <- all, into: %{}, do: {r, Map.get(map, r)}
end
