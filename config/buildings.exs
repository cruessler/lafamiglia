use Mix.Config

config :la_famiglia,
  buildings: [
    building_1: %{
      id: 1,
      key: :building_1,
      build_time: fn level -> level * 1 + 4 end,
      costs: fn level ->
        %{
        resource_1: level * 1 + 1,
        resource_2: level * 1 + 1,
        resource_3: level * 1 + 1
        }
      end,
      maxlevel: 8,
      defense: fn level -> 10 end,
      points: fn level -> :math.pow(level, 1.5) end
      },
    building_2: %{
      id: 2,
      key: :building_2,
      build_time: fn level -> level * 1 + 4 end,
      costs: fn level ->
        %{
        resource_1: level * 1 + 1,
        resource_2: level * 1 + 1,
        resource_3: level * 1 + 1
        }
      end,
      maxlevel: 8,
      defense: fn level -> 0 end,
      points: fn level -> :math.pow(level, 1.5) end
      },
    building_3: %{
      id: 3,
      key: :building_3,
      build_time: fn level -> 100 + :math.pow(level, 1.8) |> round end,
      costs: fn level ->
        %{
        resource_1: 20 + :math.pow(level, 2) |> round,
        resource_2: 20 + :math.pow(level, 2) |> round,
        resource_3: 20 + :math.pow(level, 2) |> round
        }
      end,
      maxlevel: 24,
      defense: fn level -> 0 end,
      points: fn level -> :math.pow(level, 2) end
      },
    building_4: %{
      id: 4,
      key: :building_4,
      build_time: fn level -> 100 + :math.pow(level, 1.8) |> round end,
      costs: fn level ->
        %{
        resource_1: 20 + :math.pow(level, 2) |> round,
        resource_2: 20 + :math.pow(level, 2) |> round,
        resource_3: 20 + :math.pow(level, 2) |> round
        }
      end,
      maxlevel: 24,
      defense: fn level -> 0 end,
      points: fn level -> :math.pow(level, 2) end
      },
    building_5: %{
      id: 5,
      key: :building_5,
      build_time: fn level -> 100 + :math.pow(level, 1.8) |> round end,
      costs: fn level ->
        %{
        resource_1: 20 + :math.pow(level, 2) |> round,
        resource_2: 20 + :math.pow(level, 2) |> round,
        resource_3: 20 + :math.pow(level, 2) |> round
        }
      end,
      maxlevel: 24,
      defense: fn level -> 0 end,
      points: fn level -> :math.pow(level, 2) end
      }]
