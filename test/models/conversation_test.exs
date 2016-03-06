defmodule LaFamiglia.ConversationTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Repo
  alias LaFamiglia.Conversation

  setup do
    participants =
      Forge.saved_player_list(Repo, 2)
      |> Enum.map(fn(p) -> %{id: p.id} end)

    {:ok, %{participants: participants}}
  end

  defp conversation_count do
    Repo.all(Conversation) |> Enum.count
  end

  test "create conversation", context do
    old_conversation_count = conversation_count

    message = Conversation.create(%{participants: context.participants})

    for _ <- 0..2 do assert {:ok, %{conversation: _}} = Repo.transaction(message) end

    assert conversation_count == old_conversation_count + 3
  end
end
