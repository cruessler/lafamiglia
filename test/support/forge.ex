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
    resource_1: 50.0,
    resource_2: 50.0,
    resource_3: 50.0,
    storage_capacity: 100,
    building_1: 1,
    building_2: 0,
    unit_1: 0,
    unit_2: 0,
    supply: 0,
    max_supply: 100,
    processed_until: LaFamiglia.DateTime.now,
    player_id: Forge.saved_player(Repo).id

  register :conversation,
    __struct__: Conversation

  register :message,
    __struct__: Message,
    text: "This is a text"

  register :report,
    __struct__: Report,
    title: "This is a title",
    data: %{"key" => "value"},
    read: false,
    player_id: Forge.saved_player(Repo).id,
    delivered_at: LaFamiglia.DateTime.now

  register :attack_movement,
    __struct__: AttackMovement,
    origin_id: Forge.saved_villa(Repo).id,
    target_id: Forge.saved_villa(Repo).id,
    unit_1: 100,
    unit_2: 0
end
