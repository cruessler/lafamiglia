defmodule LaFamiglia.ConversationTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Conversation

  test "create conversation" do
    participants =
      build_pair(:player)
      |> Enum.map(fn(p) -> %{id: p.id} end)

    conversation = Conversation.create(%{participants: participants})
    assert conversation.valid?
  end
end
