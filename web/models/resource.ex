defmodule LaFamiglia.Resource do
  @resources [:resource_1, :resource_2, :resource_3]

  def all, do: @resources

  def count, do: Enum.count(@resources)
end
