defmodule LaFamiglia.EventCallbacks do
  @moduledoc """
  This module contains callbacks for models that need to modify the event queue
  after they have been inserted, updated or deleted. All calls are forwarded to
  the event queue.
  """

  def send_to_queue(event) do
    LaFamiglia.EventQueue.cast({:new_event, event})

    {:ok, event}
  end

  def drop_from_queue(event) do
    LaFamiglia.EventQueue.cast({:cancel_event, event})

    {:ok, event}
  end
end
