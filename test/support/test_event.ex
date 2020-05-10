defmodule TestEvent do
  @moduledoc """
  This is a dummy implementation for testing that sends a message to be used
  with `assert_receive`.
  """

  defstruct [:id, :happens_at, :pid]

  defimpl LaFamiglia.Event do
    def happens_at(event) do
      event.happens_at
    end

    def handle(event) do
      send(event.pid, {:handle, event.id})

      {:ok, nil}
    end
  end
end
