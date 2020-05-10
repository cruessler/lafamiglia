defmodule LaFamiglia.EventQueue do
  @moduledoc """
  This module keeps a queue of all pending events (implemented using
  [ordsets](http://erlang.org/doc/man/ordsets.html)). It handles two kinds of
  messages:

  1. events coming from the webapp, e. g. new BuildingQueueItems. These events
    are put into the queue. The returned tuple contains a timeout that lasts
    until the first element of the queue is ready to be processed.
  2. timeouts occurring whenever the first event of the queue is ready to be
    processed. When that happens the event is handled.
  """

  use GenServer

  require Logger

  import Ecto.Query

  alias LaFamiglia.Event

  @store LaFamiglia.EventQueue.Store

  def start_link(opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:store, @store)

    state = %{opts: opts, queue: :ordsets.new()}

    GenServer.start_link(__MODULE__, state, name: LaFamiglia.EventQueue)
  end

  def cast(request) do
    GenServer.cast(__MODULE__, request)
  end

  def init(%{opts: opts} = state) do
    new_queue =
      opts[:store].load()
      |> Enum.map(fn e -> to_tuple(e) end)
      |> :ordsets.from_list()

    {:ok, %{state | queue: new_queue}, timeout(new_queue)}
  end

  def handle_cast({:new_event, event}, %{queue: queue} = state) do
    Logger.info("adding event ##{event.id} to queue with length #{length(queue)}")

    new_queue = :ordsets.add_element(to_tuple(event), queue)

    {:noreply, %{state | queue: new_queue}, timeout(new_queue)}
  end

  def handle_cast({:cancel_event, event}, %{queue: queue} = state) do
    Logger.info("removing event ##{event.id} from queue with length #{length(queue)}")

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
    # https://github.com/elixir-lang/ecto/pull/515
    new_queue =
      :ordsets.filter(
        fn {_, module, id} ->
          !(module == event.__struct__ && id == event.id)
        end,
        queue
      )

    {:noreply, %{state | queue: new_queue}, timeout(new_queue)}
  end

  def handle_cast({:update_event, event}, %{queue: queue} = state) do
    Logger.info("updating event ##{event.id} in queue with length #{length(queue)}")

    new_queue =
      :ordsets.filter(
        fn {_, module, id} ->
          !(module == event.__struct__ && id == event.id)
        end,
        queue
      )

    new_queue = :ordsets.add_element(to_tuple(event), new_queue)

    {:noreply, %{state | queue: new_queue}, timeout(new_queue)}
  end

  def handle_info(:timeout, %{opts: opts, queue: queue} = state) do
    [{_completed_at, module, id} | rest] = queue

    event = opts[:store].get!(module, id)

    # Until May 2020, the event was sent to another process, `EventLoop`, using
    # `notify` and handled by that process which implemented `GenEvent`.
    # `GenEvent` has been deprecated in Elixir 1.5, so `EventLoop` has been
    # removed, and the event is now handled by `EventQueue`.
    {:ok, _} = Event.handle(event)

    {:noreply, %{state | queue: rest}, timeout(rest)}
  end

  defp to_tuple(event) do
    {Event.happens_at(event), event.__struct__, event.id}
  end

  defp timeout([]) do
    :infinity
  end

  defp timeout([{happens_at, _, id} | _]) do
    timeout_in_milliseconds = max(milliseconds_until(happens_at), 0)

    Logger.info("timeout for event ##{id} will be in #{timeout_in_milliseconds} milliseconds")

    timeout_in_milliseconds
  end

  defp milliseconds_until(%DateTime{} = time) do
    # `Timex.diff/3` returns negative integers if the first `DateTime` comes
    # before the second one.
    #
    # This was a breaking change in timex 3.0.
    #
    # https://github.com/bitwalker/timex/blob/master/CHANGELOG.md#changed-1
    Timex.diff(time, DateTime.utc_now(), :milliseconds)
  end
end
