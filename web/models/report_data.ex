defmodule LaFamiglia.ReportData do
  @behaviour Ecto.Type
  def type, do: :map

  defstruct [:attacker_before_combat, :attacker_losses,
             :defender_before_combat, :defender_losses,
             :winner]

  defp atomify_keys(map) when is_map(map) do
    Enum.reduce map, %{}, fn({k, v}, acc) ->
      Map.put(acc, String.to_existing_atom(k), atomify_keys(v))
    end
  end
  defp atomify_keys(value), do: value

  def cast(%LaFamiglia.ReportData{} = data), do: {:ok, data}
  def cast(_), do: :error

  def load(map) when is_map(map) do
    {:ok, struct(LaFamiglia.ReportData, atomify_keys(map))}
  end
  # The following function clause is due to the way Ecto handles custom types
  # when using MySQL (PostgreSQL correctly returns a map).
  #
  # Even though `type` returns `:map`, the data gets passed to `load` as a
  # string. This seems to be in contrast to the Ecto documentation which states
  # that “load should receive the db type and output your custom Ecto type”.
  #
  # See http://hexdocs.pm/ecto/Ecto.Type.html
  def load(string) when is_binary(string) do
    {:ok, Poison.decode!(string, as: LaFamiglia.ReportData, keys: :atoms!)}
  end

  def dump(%LaFamiglia.ReportData{} = report_data) do
    {:ok, Map.from_struct(report_data)}
  end
  def dump(_), do: :error
end
