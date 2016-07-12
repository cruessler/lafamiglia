defmodule LaFamiglia.ConversationTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Conversation

  test "create conversation" do
    conversation = Conversation.create(%{participants: build_pair(:player)})
    assert conversation.valid?
  end
end
