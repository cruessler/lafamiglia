defmodule LaFamiglia.MessageControllerTest do
  use LaFamiglia.ConnCase

  alias LaFamiglia.Conversation

  test "create messages" do
    player = insert(:player)
    receiver = insert(:player)

    conn =
      conn
      |> with_login(player)
      |> post( "/messages", [message: [text: "This is a text.", receivers: [receiver.id]]])

    conversation =
      from(c in Conversation, preload: :participants, order_by: [desc: :id], limit: 1)
      |> Repo.one!

    assert Enum.any? conversation.participants, fn(p) -> p.id == player.id end

    conn = get conn, "/conversations/#{conversation.id}"

    assert html_response(conn, 200) =~ "This is a text."

    conn = post conn, "/conversations/#{conversation.id}/messages", [message: [text: "This is a text."]]

    assert html_response(conn, 302)
  end
end
