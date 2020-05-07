defmodule LaFamiglia.Mechanics.Buildings do
  @moduledoc """
  All build times are specified in microseconds.
  """

  alias LaFamiglia.Building

  def buildings do
    [
      %Building{
        id: 1,
        key: :building_1,
        build_time: fn level ->
          ((200 + 500 * level + :math.pow(level, 1.8)) |> round) * 1_000_000
        end,
        costs: fn level ->
          %{
            resource_1: level * 1 + 1,
            resource_2: level * 1 + 1,
            resource_3: level * 1 + 1
          }
        end,
        maxlevel: 10,
        defense: fn level -> 10 end,
        points: fn level -> :math.pow(level, 1.5) end
      },
      %Building{
        id: 2,
        key: :building_2,
        build_time: fn level ->
          ((200 + 1000 * level + :math.pow(level, 2.6)) |> round) * 1_000_000
        end,
        costs: fn level ->
          %{
            resource_1: level * 1 + 1,
            resource_2: level * 1 + 1,
            resource_3: level * 1 + 1
          }
        end,
        maxlevel: 16,
        defense: fn level -> 0 end,
        points: fn level -> :math.pow(level, 1.5) end
      },
      %Building{
        id: 3,
        key: :building_3,
        build_time: fn level -> ((100 + :math.pow(level, 1.8)) |> round) * 1_000_000 end,
        costs: fn level ->
          %{
            resource_1: (20 + :math.pow(level, 2)) |> round,
            resource_2: (20 + :math.pow(level, 2)) |> round,
            resource_3: (20 + :math.pow(level, 2)) |> round
          }
        end,
        maxlevel: 24,
        defense: fn level -> 0 end,
        points: fn level -> :math.pow(level, 2) end
      },
      %Building{
        id: 4,
        key: :building_4,
        build_time: fn level -> ((100 + :math.pow(level, 1.8)) |> round) * 1_000_000 end,
        costs: fn level ->
          %{
            resource_1: (20 + :math.pow(level, 2)) |> round,
            resource_2: (20 + :math.pow(level, 2)) |> round,
            resource_3: (20 + :math.pow(level, 2)) |> round
          }
        end,
        maxlevel: 24,
        defense: fn level -> 0 end,
        points: fn level -> :math.pow(level, 2) end
      },
      %Building{
        id: 5,
        key: :building_5,
        build_time: fn level -> ((100 + :math.pow(level, 1.8)) |> round) * 1_000_000 end,
        costs: fn level ->
          %{
            resource_1: (20 + :math.pow(level, 2)) |> round,
            resource_2: (20 + :math.pow(level, 2)) |> round,
            resource_3: (20 + :math.pow(level, 2)) |> round
          }
        end,
        maxlevel: 24,
        defense: fn level -> 0 end,
        points: fn level -> :math.pow(level, 2) end
      },
      %Building{
        id: 6,
        key: :building_6,
        build_time: fn level ->
          ((200 + 400 * level + :math.pow(level, 2.2)) |> round) * 1_000_000
        end,
        costs: fn level ->
          %{
            resource_1: (20 + :math.pow(level, 2.5)) |> round,
            resource_2: (20 + :math.pow(level, 2.5)) |> round,
            resource_3: (20 + :math.pow(level, 2.5)) |> round
          }
        end,
        maxlevel: 16,
        defense: fn level -> 0 end,
        points: fn level -> :math.pow(level, 2.5) |> round end
      }
    ]
  end
end
