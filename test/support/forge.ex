defmodule Forge do
  use Blacksmith

  alias LaFamiglia.Player
  alias LaFamiglia.Villa

  @save_one_function &Blacksmith.Config.save/2
  @save_all_function &Blacksmith.Config.save_all/2

  register :player,
    __struct__: Player,
    email: Sequence.next(:email, &"test#{&1}@example.com"),
    password: "password",
    password_confirmation: "password",
    name: Faker.Name.name,
    points: 0

  register :villa,
    __struct__: Villa,
    name: "New Villa",
    x: Sequence.next(:x),
    y: Sequence.next(:y),
    resource_1: 0.0,
    resource_2: 0.0,
    resource_3: 0.0,
    storage_capacity: 100,
    building_1: 1,
    building_2: 0,
    processed_until: Ecto.DateTime.local
end
