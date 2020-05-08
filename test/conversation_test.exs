defmodule LaFamiglia.ConversationTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Conversation
  alias LaFamiglia.Message

  test "create conversation" do
    conversation = Conversation.create(%{participants: build_pair(:player)})
    assert conversation.valid?
  end

  test "mark conversation as read" do
    conversation = build(:conversation)
    sender = hd(conversation.participants)

    changeset = Message.continue_conversation(sender, conversation, "This is a text.")

    message = apply_changes(changeset)

    assert hd(message.conversation.participants).unread_conversations == 1

    changeset = Conversation.update_read_until_for(message.sender, message.conversation)

    assert get_field(changeset, :unread_conversations) == 0
  end
end
