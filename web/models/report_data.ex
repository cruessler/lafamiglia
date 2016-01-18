defmodule LaFamiglia.ReportData do
  @behavior Ecto.Type
  def type, do: :map

  defstruct [:attacker, :attacker_losses,
             :attacker_after_combat, :attacker_supply_loss,
             :defender, :defender_losses,
             :defender_after_combat, :defender_supply_loss,
             :winner, :attacker_survived?]

  def cast(%LaFamiglia.ReportData{} = data), do: {:ok, data}
  def cast(_), do: :error

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
