defmodule LaFamigliaWeb.MessageController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player
  alias LaFamiglia.ConversationStatus
  alias LaFamiglia.Message

  def create(
        conn,
        %{"conversation_id" => conversation_id, "message" => %{"text" => text}} = _params
      ) do
    conversation =
      from(s in ConversationStatus,
        join: c in assoc(s, :conversation),
        where:
          c.id == ^conversation_id and
            s.player_id == ^conn.assigns.current_player.id,
        select: c
      )
      |> Repo.one!()

    Message.continue_conversation(conn.assigns.current_player, conversation, text)
    |> Repo.insert()

    redirect(conn, to: Routes.conversation_path(conn, :show, conversation.id))
  end

  def create(conn, %{"message" => %{"text" => text, "receivers" => receivers}} = _params) do
    receivers =
      from(p in Player, where: p.id in ^receivers)
      |> Repo.all()
      |> Enum.uniq()

    changeset = Message.open_conversation(conn.assigns.current_player, receivers, text)

    case Repo.insert(changeset) do
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")

      {:ok, message} ->
        conn
        |> redirect(to: Routes.conversation_path(conn, :show, message.conversation_id))
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
