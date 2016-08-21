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
  alias LaFamiglia.Occupation

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
      from(m in ComebackMovement,  order_by: [asc: m.arrives_at]),
      from(o in Occupation,        order_by: [asc: o.succeeds_at])
    ]

    queue =
      queries
      |> Enum.map(&Repo.all/1)
      |> Enum.concat
      |> Enum.map(fn(e) -> to_tuple(e) end)
      |> :ordsets.from_list

    {:ok, queue, timeout(queue)}
  end

  def handle_cast({:new_event, event}, queue) do
    Logger.info "adding event ##{event.id} to queue with length #{length(queue)}"

    new_queue = :ordsets.add_element(to_tuple(event), queue)

    {:noreply, new_queue, timeout(new_queue)}
  end
  def handle_cast({:cancel_event, event}, queue) do
    Logger.info "removing event ##{event.id} from queue with length #{length(queue)}"

    # This is a workaround for MySQL. Even though MySQL supports microseconds
    # precision in datetimes (since 5.6.4), by default it is not used in Ecto.
    # Thus, datetimes are currently only saved with seconds precision.
    #
    # Therefore, the following line does not work in case the event has been
    # loaded from MySQL because it would only have seconds precision while the
    # event already in the queue has microseconds precision (assuming the event
    # loop has not been restarted).
    #
    #   new_queue = :ordsets.del_element(to_tuple(event), queue)
    #
    # See http://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html,
    # https://github.com/elixir-lang/ecto/pull/515),
    new_queue = :ordsets.filter(fn({_, module, id}) ->
      !(module == event.__struct__ && id == event.id)
    end, queue)

    {:noreply, new_queue, timeout(new_queue)}
  end
  def handle_cast({:update_event, event}, queue) do
    Logger.info "updating event ##{event.id} in queue with length #{length(queue)}"

    new_queue = :ordsets.filter(fn({_, module, id}) ->
      !(module == event.__struct__ && id == event.id)
    end, queue)

    new_queue = :ordsets.add_element(to_tuple(event), new_queue)

    {:noreply, new_queue, timeout(new_queue)}
  end

  def handle_info(:timeout, [{_completed_at, module, id}|queue]) do
    event = Repo.get!(module, id)

    LaFamiglia.EventLoop.notify(event)

    {:noreply, queue, timeout(queue)}
  end

  defp to_tuple(event) do
    {Event.happens_at(event), event.__struct__, event.id}
  end

  defp timeout([]) do
    :infinity
  end
  defp timeout([{happens_at, _, _}|_]) do
    max(milliseconds_until(happens_at), 0)
  end

  defp milliseconds_until(%Ecto.DateTime{} = time) do
    diff_seconds = LaFamiglia.DateTime.time_diff(Ecto.DateTime.utc(:usec), time)
    trunc(diff_seconds * 1_000)
  end
end
