defmodule LaFamiglia.EventLoop do
  @moduledoc """
  This module handles events.
  """

  use GenEvent

  def start_link(opts \\ []) do
    {:ok, pid} = GenEvent.start_link(Dict.put(opts, :name, __MODULE__))

    GenEvent.add_handler(pid, __MODULE__, [])

    {:ok, pid}
  end

  def notify(request) do
    GenEvent.notify(__MODULE__, request)
  end

  def handle_event(event, state) do
    LaFamiglia.Event.handle(event)

    {:ok, state}
  end
end
