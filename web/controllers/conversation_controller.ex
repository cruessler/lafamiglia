defmodule LaFamiglia.ConversationController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player
  alias LaFamiglia.ConversationStatus
  alias LaFamiglia.Conversation
  alias LaFamiglia.Message

  def index(conn, _params) do
    conversations =
      assoc(conn.assigns.current_player, :conversations)
      |> Repo.all
      |> Repo.preload([:messages, :players])

    conn
    |> assign(:conversation, %Conversation{})
    |> assign(:conversations, conversations)
    |> assign(:changeset, Ecto.Changeset.change(%Message{}))
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    conversation  = Repo.get(Conversation, id) |> Repo.preload([messages: :sender])
    conversations =
      assoc(conn.assigns.current_player, :conversations)
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
