defmodule LaFamiglia.Factory do
  use ExMachina.Ecto, repo: LaFamiglia.Repo

  alias LaFamiglia.{Building, Unit}

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
      player: build(:player, %{points: 1})
    }
  end

  def with_building_queue(villa) do
    %{villa | building_queue_items: building_queue}
  end

  def building_queue do
    build_times = [
      Building.build_time(Building.get(1), 1),
      Building.build_time(Building.get(1), 2)
    ]

    completed_at = [
      LaFamiglia.DateTime.from_now(Enum.at(build_times, 0)),
      LaFamiglia.DateTime.from_now(Enum.at(build_times, 0) + Enum.at(build_times, 1))
    ]

    for {t, c} <- Enum.zip(build_times, completed_at) do
      build(:building_queue_item, %{build_time: t, completed_at: c})
    end
  end

  def building_queue_item_factory() do
    %LaFamiglia.BuildingQueueItem{
      building_id: 1
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

  def conversation_factory do
    sent_at = LaFamiglia.DateTime.from_now(-10)

    participants = build_list(3, :player, %{unread_conversations: 0})

    statuses = for p <- participants do
      %LaFamiglia.ConversationStatus{
        player: p,
        read_until: sent_at
      }
    end

    %LaFamiglia.Conversation{
      participants: participants,
      conversation_statuses: statuses,
      last_message_sent_at: sent_at
    }
  end

  def attack_factory do
    %LaFamiglia.AttackMovement{
      origin: build(:villa),
      target: build(:villa, %{unit_queue_items: []}),
      arrives_at: LaFamiglia.DateTime.from_now(10),
      unit_1: 100,
      unit_2: 0
    }
  end

  def occupation_factory do
    %LaFamiglia.Occupation{
      origin: build(:villa),
      target: build(:villa, %{is_occupied: true}),
      unit_1: 100,
      unit_2: 2,
      succeeds_at: LaFamiglia.DateTime.from_now(10)
    }
  end

  def comeback_factory do
    %LaFamiglia.ComebackMovement{
      origin: build(:villa),
      target: build(:villa),
      arrives_at: LaFamiglia.DateTime.from_now(10),
      unit_1: 100,
      unit_2: 0,
      resource_1: 50,
      resource_2: 60,
      resource_3: 70
    }
  end

  def report_factory do
    [origin, target] = build_pair(:villa)

    %LaFamiglia.Report{
      title: "Attack on a villa",
      player: build(:player),
      delivered_at: LaFamiglia.DateTime.now,
      read: false,
      origin: origin,
      target: target
    }
  end

  def combat_report_factory do
    build(:report, combat_report: %LaFamiglia.CombatReport{})
  end

  def conquest_report_factory do
    build(:report, conquest_report: %LaFamiglia.ConquestReport{})
  end
end
