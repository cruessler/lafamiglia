defmodule LaFamiglia.EventCallbacks do
  @moduledoc """
  This module contains callbacks for models that need to modify the event queue
  after they have been inserted, updated or deleted. Most calls are forwarded
  to the event queue.
  """

  def after_insert(changeset) do
    LaFamiglia.EventQueue.cast({:new_event, changeset.model})

    changeset
  end

  def after_update(changeset) do
    LaFamiglia.EventQueue.cast({:update_event, changeset.model})

    changeset
  end

  def after_delete(changeset) do
    # The flag `processed` indicates that the model has been deleted by the
    # event loop. In that case, it does not have to be removed from the event
    # loop.
    unless changeset.model.processed do
      LaFamiglia.EventQueue.cast({:cancel_event, changeset.model})
    end

    changeset
  end
end
