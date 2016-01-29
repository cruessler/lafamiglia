defmodule LaFamiglia.TestEventQueue do
  @moduledoc """
  This is a dummy implementation for testing that does nothing.
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Dict.put(opts, :name, LaFamiglia.EventQueue))
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end
end
