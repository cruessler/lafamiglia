defmodule LaFamiglia.ConversationController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Conversation
  alias LaFamiglia.ConversationStatus
  alias LaFamiglia.Message

  def index(conn, _params) do
    conn
    |> load_conversations
    |> assign(:conversation, %Conversation{})
    |> assign(:changeset, Ecto.Changeset.change(%Message{}))
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    conversation =
      from(c in assoc(conn.assigns.current_player, :conversations),
        where: c.id == ^id)
      |> Repo.one
      |> Repo.preload([messages: :sender])

    ConversationStatus.update_read_until!(conversation, conn.assigns.current_player)

    changeset =
      Ecto.Changeset.change(%Message{},
                            %{conversation_id: conversation.id,
                              sender_id: conn.assigns.current_player.id})

    conn
    |> load_conversations
    |> assign(:conversation, conversation)
    |> assign(:changeset, changeset)
    |> render("show.html")
  end

  defp load_conversations(conn) do
    current_player = conn.assigns.current_player

    conversations =
      from(c in assoc(current_player, :conversations),
        left_join: s in assoc(c, :conversation_statuses),
        where: s.player_id == ^current_player.id,
        select: {c, c.last_message_sent_at > s.read_until or is_nil(s.read_until)},
        order_by: [desc: c.last_message_sent_at])
      |> Repo.all
      # FIXME: This code is specific to MySQL. MySQL does not have native
      # boolean data types and uses `1` and `0` for `true` and `false`, both of
      # which cannot be cast automatically by Ecto as it does not know we want
      # a boolean here.
      |> Enum.map(fn {c, new_messages} -> %{c | new_messages: new_messages == 1} end)
      |> Repo.preload([:players])

    conn
    |> assign(:conversations, conversations)
  end
end
