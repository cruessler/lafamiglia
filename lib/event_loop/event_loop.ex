defmodule LaFamiglia.EventLoop do
  @moduledoc """
  This module handles events.
  """

  use GenEvent

  require Logger

  import Ecto.Model

  alias LaFamiglia.EventQueue

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.Unit
  alias LaFamiglia.BuildingQueueItem
  alias LaFamiglia.UnitQueueItem
  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement

  def start_link(opts \\ []) do
    {:ok, pid} = GenEvent.start_link(Dict.put(opts, :name, __MODULE__))

    GenEvent.add_handler(pid, __MODULE__, [])

    {:ok, pid}
  end

  def notify(request) do
    GenEvent.notify(__MODULE__, request)
  end

  def handle_event(%BuildingQueueItem{} = item, state) do
    Logger.info "processing build event ##{item.id}"

    building = Building.get_by_id(item.building_id)
    key      = building.key
    villa    = assoc(item, :villa) |> Repo.one

    changeset = Villa.changeset(villa, Map.put(%{}, key, Map.get(villa, key) + 1))

    Repo.transaction fn ->
      Repo.update!(changeset)
      Repo.delete!(%BuildingQueueItem{item | processed: true})
    end

    {:ok, state}
  end
  def handle_event(%UnitQueueItem{} = item, state) do
    Logger.info "processing recruiting event ##{item.id}"

    unit  = Unit.get_by_id(item.unit_id)
    key   = unit.key
    villa = assoc(item, :villa) |> Repo.one

    changeset = Villa.changeset(villa, Map.put(%{}, key, Map.get(villa, key) + item.number))

    Repo.transaction fn ->
      Repo.update!(changeset)
      Repo.delete!(%UnitQueueItem{item | processed: true})
    end

    {:ok, state}
  end
  def handle_event(%AttackMovement{} = attack, state) do
    Logger.info "processing attack event ##{attack.id}"

    LaFamiglia.DateTime.clock!

    {:ok, comeback} = AttackMovement.cancel!(attack)
    EventQueue.cast({:new_event, comeback})

    {:ok, state}
  end
  def handle_event(%ComebackMovement{} = comeback, state) do
    Logger.info "processing comeback event ##{comeback.id}"

    LaFamiglia.DateTime.clock!

    ComebackMovement.arrive!(comeback)

    {:ok, state}
  end
end
