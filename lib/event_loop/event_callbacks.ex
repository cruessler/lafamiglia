defmodule LaFamiglia.EventCallbacks do
  @moduledoc """
  This module contains callbacks for models that need to modify the event queue
  after they have been inserted, updated or deleted. Most calls are forwarded
  to the event queue.
  """

  def send_to_queue(event) do
    LaFamiglia.EventQueue.cast({:new_event, event})

    {:ok, event}
  end

  def after_insert(changeset) do
    LaFamiglia.EventQueue.cast({:new_event, changeset.data})

    changeset
  end

  def after_update(changeset) do
    LaFamiglia.EventQueue.cast({:update_event, changeset.data})

    changeset
  end

  def drop_from_queue(event) do
    LaFamiglia.EventQueue.cast({:cancel_event, event})

    {:ok, event}
  end

  def after_delete(changeset) do
    # The flag `processed` indicates that the model has been deleted by the
    # event loop. In that case, it does not have to be removed from the event
    # loop.
    unless changeset.data.processed do
      LaFamiglia.EventQueue.cast({:cancel_event, changeset.data})
    end

    changeset
  end
end
