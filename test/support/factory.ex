defmodule LaFamiglia.Factory do
  use ExMachina.Ecto, repo: LaFamiglia.Repo

  alias LaFamiglia.Unit

  @hashed_password Comeonin.Bcrypt.hashpwsalt("password")

  def player_factory do
    %LaFamiglia.Player{
      name: sequence(:player, &"Player #{&1}"),
      email: sequence(:email, &"test#{&1}@example.com"),
      password: "password",
      password_confirmation: "password",
      hashed_password: @hashed_password,
      points: 0
    }
  end

  def villa_factory do
    %LaFamiglia.Villa{
      name: "New Villa",
      x: sequence(:x, &(&1)),
      y: sequence(:y, &(&1)),
      is_occupied: false,
      resource_1: 50.0,
      resource_2: 50.0,
      resource_3: 50.0,
      # `storage_capacity` needs to be set here for testing as
      # `Villa.recalc_storage_capacity` is not called automatically.
      storage_capacity: 100,
      building_1: 1,
      building_2: 0,
      building_3: 0,
      building_4: 0,
      building_5: 0,
      building_6: 0,
      unit_1: 0,
      unit_2: 0,
      building_queue_items: [],
      unit_queue_items: [],
      points: 1,
      supply: 0,
      # `max_supply` needs to be set here for testing as
      # `Villa.recalc_max_supply` is not called automatically.
      max_supply: 100,
      resources_gained_until: LaFamiglia.DateTime.now,
      units_recruited_until: LaFamiglia.DateTime.now,
      player: build(:player)
    }
  end

  @build_time Unit.build_time(Unit.get(1), 10)

  def with_unit_queue(villa) do
    items = [
      build(:unit_queue_item, %{completed_at: LaFamiglia.DateTime.from_now(@build_time)}),
      build(:unit_queue_item, %{completed_at: LaFamiglia.DateTime.from_now(2 * @build_time)})
    ]

    %{villa | unit_queue_items: items}
  end

  def unit_queue_item_factory do
    %LaFamiglia.UnitQueueItem{
      unit_id: 1,
      number: 10,
      build_time: @build_time
    }
  end
end
