defmodule LaFamiglia.MessageTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Conversation
  alias LaFamiglia.ConversationStatus
  alias LaFamiglia.Message

  setup do
    sender_id = Forge.saved_player(Repo).id
    receivers =
      Forge.saved_player_list(Repo, 2)
      |> Enum.map(fn(p) -> %{id: p.id} end)

    message_params = %{sender_id: sender_id,
                       receivers: receivers,
                       text: "This is a text."}

    {:ok, %{sender_id: sender_id,
            receivers: receivers,
            message_params: message_params}}
  end

  defp conversation_count do
    Repo.all(Conversation) |> Enum.count
  end

  test "create message", %{sender_id: sender_id, receivers: receivers} = context do
    invalid_messages = [
      %{text: "This is a text"}, # has neither sender nor receivers
      %{sender_id: sender_id,
        receivers: receivers,
        text: ""}                # has no text
      ]

    Enum.map invalid_messages, fn(m) ->
      assert {:error, _} = Message.changeset(%Message{}, m)
                           |> Repo.insert
    end

    multi = Message.open_conversation(%{id: sender_id}, receivers, "This is a text.")

    assert {:ok, %{message: message}} = Repo.transaction(multi)

    statuses =
      from(s in ConversationStatus,
        where: s.conversation_id == ^message.conversation_id)
      |> Repo.all

    assert length(statuses) == length(receivers) + 1
  end

  test "add message to existing conversation", context do
    old_conversation_count = conversation_count

    conversation = Forge.saved_conversation(Repo)
    multi =
      Message.continue_conversation(
        %{id: context.sender_id}, conversation, "This is a text.")

    for _ <- 0..2 do
      assert {:ok, %{message: message}} = Repo.transaction(multi)
      message = Repo.preload(message, :conversation)

      assert message.inserted_at == message.conversation.last_message_sent_at
    end

    assert conversation_count == old_conversation_count + 1
  end
end
