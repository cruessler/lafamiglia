defmodule Forge do
  use Blacksmith

  alias LaFamiglia.Repo
  alias LaFamiglia.Player
  alias LaFamiglia.Villa
  alias LaFamiglia.Conversation
  alias LaFamiglia.Message
  alias LaFamiglia.Report
  alias LaFamiglia.AttackMovement

  @save_one_function &Blacksmith.Config.save/2
  @save_all_function &Blacksmith.Config.save_all/2

  @hashed_password Comeonin.Bcrypt.hashpwsalt("password")

  register :player,
    __struct__: Player,
    email: Sequence.next(:email, &"test#{&1}@example.com"),
    password: "password",
    password_confirmation: "password",
    hashed_password: @hashed_password,
    name: Faker.Name.name,
    points: 0

  register :villa,
    __struct__: Villa,
    name: "New Villa",
    x: Sequence.next(:x),
    y: Sequence.next(:y),
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
    points: 1,
    supply: 0,
    # `max_supply` needs to be set here for testing as
    # `Villa.recalc_max_supply` is not called automatically.
    max_supply: 100,
    resources_gained_until: LaFamiglia.DateTime.now,
    units_recruited_until: LaFamiglia.DateTime.now,
    player_id: Forge.saved_player(Repo).id

  register :conversation,
    __struct__: Conversation

  register :message,
    __struct__: Message,
    text: "This is a text"

  register :report,
    __struct__: Report,
    title: "This is a title",
    data: %LaFamiglia.ReportData{},
    read: false,
    player_id: Forge.saved_player(Repo).id,
    delivered_at: LaFamiglia.DateTime.now

  register :attack_movement,
    __struct__: AttackMovement,
    origin_id: Forge.saved_villa(Repo).id,
    target_id: Forge.saved_villa(Repo).id,
    arrives_at: LaFamiglia.DateTime.from_now(10),
    unit_1: 100,
    unit_2: 0
end
