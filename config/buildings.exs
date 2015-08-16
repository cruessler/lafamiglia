use Mix.Config

config :la_famiglia,
  buildings: [
    building_1: %{
      id: 1,
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
      }]
