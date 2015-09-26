defmodule LaFamiglia.MessageTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Message

  test "create message" do
    sender_id = Forge.saved_player(Repo).id
    receivers =
      Forge.saved_player_list(Repo, 2)
      |> Enum.map fn(p) -> %{id: p.id} end

    invalid_messages = [
      %{text: "This is a text"}, # has neither sender nor receivers
      %{sender_id: sender_id,
        receivers: receivers,
        text: ""}                # has no text
      ]

    invalid_messages |> Enum.map fn(m) ->
      assert {:error, _} = Message.changeset(%Message{}, m)
                           |> Repo.insert
    end

    message_params = %{sender_id: sender_id,
                       receivers: receivers,
                       text: "This is a text."}
    message = Message.changeset(%Message{}, message_params)

    assert {:ok, _} = Repo.insert(message)
  end
end
