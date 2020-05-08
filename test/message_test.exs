defmodule LaFamiglia.MessageTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Message

  setup do
    {:ok, %{sender: insert(:player)}}
  end

  test "validate message", %{sender: sender} do
    invalid_messages = [
      # has neither sender nor receivers
      %{text: "This is a text"},
      %{
        sender: sender,
        receivers: build_pair(:player),
        # has no text
        text: ""
      }
    ]

    Enum.map(invalid_messages, fn m ->
      refute Message.changeset(%Message{}, m).valid?
    end)
  end

  test "create message", %{sender: sender} do
    receivers = insert_pair(:player)

    changeset = Message.open_conversation(sender, receivers, "This is a text.")
    participants = get_change(changeset, :conversation) |> get_field(:participants)
    first = hd(participants)

    assert changeset.valid?
    assert length(participants) == 3
    assert first.unread_conversations == 1
  end

  test "add message to existing conversation" do
    conversation = build(:conversation)
    sender = hd(conversation.participants)

    changeset = Message.continue_conversation(sender, conversation, "This is a text.")

    conversation = get_field(changeset, :conversation)
    first = hd(conversation.participants)

    assert changeset.valid?
    assert conversation.last_message_sent_at == get_change(changeset, :sent_at)
    assert first.unread_conversations == 1

    message = apply_changes(changeset)

    changeset =
      Message.continue_conversation(message.sender, message.conversation, "This is a text.")

    conversation = get_field(changeset, :conversation)
    first = hd(conversation.participants)

    assert changeset.valid?
    assert conversation.last_message_sent_at == get_change(changeset, :sent_at)
    assert first.unread_conversations == 1
  end
end
