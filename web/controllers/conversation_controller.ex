defmodule LaFamiglia.ConversationController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player
  alias LaFamiglia.ConversationStatus
  alias LaFamiglia.Conversation
  alias LaFamiglia.Message

  def index(conn, _params) do
    conversations =
      from(c in assoc(conn.assigns.current_player, :conversations),
        order_by: [desc: c.last_message_sent_at])
      |> Repo.all
      |> Repo.preload([:players])

    conn
    |> assign(:conversation, %Conversation{})
    |> assign(:conversations, conversations)
    |> assign(:changeset, Ecto.Changeset.change(%Message{}))
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    conversation  = Repo.get(Conversation, id) |> Repo.preload([messages: :sender])
    conversations =
      from(c in assoc(conn.assigns.current_player, :conversations),
        order_by: [desc: c.last_message_sent_at])
      |> Repo.all
      |> Repo.preload([:players])

    conn
    |> assign(:conversation, conversation)
    |> assign(:conversations, conversations)
    |> assign(:changeset, Ecto.Changeset.change(%Message{},
                                                %{conversation_id: conversation.id,
                                                  sender_id: conn.assigns.current_player.id}))
    |> render("show.html")
  end
end
