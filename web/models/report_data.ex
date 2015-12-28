defmodule LaFamiglia.ReportData do
  defstruct [:attacker, :defender, :winner]

  def atomize_keys(map) when is_map(map) do
    Enum.map map, fn({k, v}) ->
      {String.to_existing_atom(k), atomize_keys(v)}
    end
  end
  def atomize_keys(value), do: value

  def from_map(data) do
    struct(__MODULE__, atomize_keys(data))
  end
end
