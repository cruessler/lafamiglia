defmodule LaFamiglia.EventQueue do
  @moduledoc """
  This module keeps a queue of all pending events (implemented using
  [ordsets](http://erlang.org/doc/man/ordsets.html)). It handles two kinds of
  messages:

  1. events coming from the webapp, e. g. new BuildingQueueItems. These events
    are put in the queue. The returned tuple contains a timeout that lasts until
    the first element of the queue is ready to be processed.
  2. timeouts occurring whenever the first event of the queue is ready to be
    processed. When that happens a message is sent to the event loop which in
    turn handles the event.
  """

  use GenServer

  require Logger

  import Ecto.Query

  alias LaFamiglia.Event

  alias LaFamiglia.Repo
  alias LaFamiglia.BuildingQueueItem
  alias LaFamiglia.UnitQueueItem
  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Dict.put(opts, :name, LaFamiglia.EventQueue))
  end

  def cast(request) do
    GenServer.cast(__MODULE__, request)
  end

  def init(_args) do
    queries = [
      from(i in BuildingQueueItem, order_by: [asc: i.completed_at]),
      from(i in UnitQueueItem,     order_by: [asc: i.completed_at]),
      from(m in AttackMovement,    order_by: [asc: m.arrives_at]),
      from(m in ComebackMovement,  order_by: [asc: m.arrives_at])
    ]

    queue =
      queries
      |> Enum.map(&Repo.all/1)
      |> Enum.concat
      |> Enum.map(fn(e) -> {Event.happens_at(e), e} end)
      |> :ordsets.from_list

    {:ok, queue, timeout(queue)}
  end

  def handle_cast({:new_event, event}, queue) do
    Logger.info "adding event ##{event.id} to queue with length #{length(queue)}"

    new_queue = :ordsets.add_element({Event.happens_at(event), event}, queue)

    {:noreply, new_queue, timeout(new_queue)}
  end
  def handle_cast({:cancel_event, event}, queue) do
    Logger.info "removing event ##{event.id} from queue with length #{length(queue)}"

    new_queue = :ordsets.filter(fn({_happens_at, e}) ->
      !(event.__struct__ == e.__struct__ && event.id == e.id)
    end, queue)

    {:noreply, new_queue, timeout(new_queue)}
  end
  def handle_cast({:update_event, event}, queue) do
    Logger.info "updating event ##{event.id} in queue with length #{length(queue)}"

    new_queue = :ordsets.filter(fn({_happens_at, e}) ->
      !(event.__struct__ == e.__struct__ && event.id == e.id)
    end, queue)

    new_queue = :ordsets.add_element({Event.happens_at(event), event}, new_queue)

    {:noreply, new_queue, timeout(new_queue)}
  end

  def handle_info(:timeout, [{_completed_at, event}|queue]) do
    LaFamiglia.EventLoop.notify(event)

    {:noreply, queue, timeout(queue)}
  end

  defp timeout([]) do
    :infinity
  end
  defp timeout([{happens_at, _event}|_]) do
    max(milliseconds_until(happens_at), 0)
  end

  defp milliseconds_until(%Ecto.DateTime{} = time) do
    diff_seconds = LaFamiglia.DateTime.to_seconds(time) - LaFamiglia.DateTime.to_seconds(Ecto.DateTime.utc)
    trunc(diff_seconds * 1_000)
  end
end
