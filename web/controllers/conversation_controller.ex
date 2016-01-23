defmodule LaFamiglia.ConversationController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Conversation
  alias LaFamiglia.Message

  plug :load_conversations

  def index(conn, _params) do
    conn
    |> assign(:conversation, %Conversation{})
    |> assign(:changeset, Ecto.Changeset.change(%Message{}))
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    conversation =
      Repo.get(Conversation, id)
      |> Repo.preload([messages: :sender])
    changeset =
      Ecto.Changeset.change(%Message{},
                            %{conversation_id: conversation.id,
                              sender_id: conn.assigns.current_player.id})

    conn
    |> assign(:conversation, conversation)
    |> assign(:changeset, changeset)
    |> render("show.html")
  end

  defp load_conversations(conn, _params) do
    conversations =
      from(c in assoc(conn.assigns.current_player, :conversations),
        order_by: [desc: c.last_message_sent_at])
      |> Repo.all
      |> Repo.preload([:players])

    conn
    |> assign(:conversations, conversations)
  end
end
