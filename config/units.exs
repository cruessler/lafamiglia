use Mix.Config

config :la_famiglia,
  units: [
    unit_1: %{
      id: 1,
      key: :unit_1,
      build_time: 10,
      costs: %{
        resource_1: 1,
        resource_2: 0,
        resource_3: 1
      },
      supply: 5,
      speed: 2
    },
    unit_2: %{
      id: 2,
      key: :unit_2,
      build_time: 43400,
      costs: %{
        resource_1: 50,
        resource_2: 50,
        resource_3: 50
      },
      supply: 20,
      speed: 1
    }]
