defmodule LaFamiglia.MessageControllerTest do
  use LaFamiglia.ConnCase

  alias LaFamiglia.Conversation

  setup do
    player = Forge.saved_player(Repo)
    conn   = conn |> with_login(player)

    {:ok, %{conn: conn, player: player}}
  end

  test "create messages", context do
    receiver = Forge.saved_player(Repo)

    conn = post context.conn, "/messages", [message: [text: "This is a text.", receivers: [receiver.id]]]

    conversation =
      from(c in Conversation, preload: :players, order_by: [desc: :id], limit: 1)
      |> Repo.one!

    assert Enum.any? conversation.players, fn(p) -> p.id == context.player.id end

    conn = get conn, "/conversations/#{conversation.id}"

    assert html_response(conn, 200) =~ "This is a text."

    conn = post conn, "/conversations/#{conversation.id}/messages", [message: [text: "This is a text."]]

    assert html_response(conn, 302)
  end
end
