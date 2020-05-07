defmodule LaFamiglia.Mechanics do
  @moduledoc """
  All resource gains are specified in resource/hour.
  """

  def resource_gains(villa) do
    %{
      resource_1: 30 + :math.pow(villa.building_3, 2.5),
      resource_2: 30 + :math.pow(villa.building_4, 2.5),
      resource_3: 30 + :math.pow(villa.building_5, 2.5)
    }
  end

  def storage_capacity(villa) do
    (100 + 200 * villa.building_2 + :math.pow(villa.building_2, 2.1)) |> round
  end

  def max_supply(villa) do
    (100 + 100 * villa.building_2 + :math.pow(villa.building_2, 1.4)) |> round
  end

  def unit_for_occupation, do: :unit_2
end
