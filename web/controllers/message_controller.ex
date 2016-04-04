defmodule LaFamiglia.MessageController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player
  alias LaFamiglia.ConversationStatus
  alias LaFamiglia.Message

  def create(conn, %{"conversation_id" => conversation_id, "message" => %{"text" => text}} = _params) do
    conversation_status =
      from(s in ConversationStatus,
        where: s.conversation_id == ^conversation_id and
               s.player_id == ^conn.assigns.current_player.id)
      |> Repo.one
      |> Repo.preload(:conversation)

    message_params = %{conversation_id: conversation_status.conversation.id,
                       sender_id: conn.assigns.current_player.id,
                       text: text}
    message = Message.changeset(%Message{}, message_params)

    case Repo.insert(message) do
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
      {:ok, _message} ->
        conn
        |> redirect(to: conversation_path(conn, :show, conversation_status.conversation.id))
    end
  end
  def create(conn, %{"message" => %{"text" => text, "receivers" => receivers}} = _params) do
    receivers =
      from(p in Player,
        select: %{id: p.id},
        where: p.id in ^receivers)
      |> Repo.all

    message_params = %{sender_id: conn.assigns.current_player.id,
                       receivers: receivers,
                       text: text}
    message = Message.changeset(%Message{}, message_params)

    case Repo.insert(message) do
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
      {:ok, _message} ->
        conn
        |> put_flash(:info, "The message has been sent.")
        |> redirect(to: conversation_path(conn, :index))
    end
  end
  # When no receiver is selected, `receivers[]` is not part of `params` and the
  # above function clause does not match. To prevent a FunctionClauseError and
  # to make the usual validation work as expected, an empty list is added to
  # `params`.
  def create(conn, %{"message" => message} = params) do
    create(conn, %{params | "message" => Dict.put(message, "receivers", [])})
  end
end
