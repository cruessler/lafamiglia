defmodule LaFamiglia.MessageTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Conversation
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

    message = Message.changeset(%Message{}, context.message_params)

    assert {:ok, _} = Repo.insert(message)
  end

  test "add message to existing conversation", context do
    old_conversation_count = conversation_count

    message = Message.changeset(%Message{}, context.message_params)

    for _ <- 0..2 do assert {:ok, _} = Repo.insert(message) end

    assert conversation_count == old_conversation_count + 1
  end
end
