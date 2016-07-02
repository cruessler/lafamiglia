defmodule LaFamiglia.MessageTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Message

  setup do
    {:ok, %{sender: insert(:player)}}
  end

  test "validate message", %{sender: sender} do
    invalid_messages = [
      %{text: "This is a text"}, # has neither sender nor receivers
      %{sender_id: sender.id,
        receivers: build_pair(:player),
        text: ""}                # has no text
      ]

    Enum.map invalid_messages, fn(m) ->
      refute Message.changeset(%Message{}, m).valid?
    end
  end

  test "create message", %{sender: sender} do
    receivers = insert_pair(:player) |> Enum.map(fn(p) -> %{id: p.id} end)

    changeset = Message.open_conversation(%{id: sender.id}, receivers, "This is a text.")

    assert changeset.valid?
    assert get_change(changeset, :conversation) |> get_field(:conversation_statuses) |> length == 3
  end

  test "add message to existing conversation", context do
    conversation = build(:conversation)
    changeset =
      Message.continue_conversation(
        %{id: context.sender.id}, conversation, "This is a text.")

    assert changeset.valid?
    assert get_change(changeset, :sent_at) ==
      get_change(changeset, :conversation)
      |> get_change(:last_message_sent_at)
  end
end
