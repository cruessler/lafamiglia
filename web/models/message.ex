defmodule LaFamiglia.Message do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Conversation
  alias LaFamiglia.Message

  schema "messages" do
    belongs_to :sender, Player
    belongs_to :conversation, Conversation

    field :text, :string
    field :sent_at, Ecto.DateTime

    field :receivers, {:array, :map}, virtual: true

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:text, :sent_at, :conversation_id, :receivers])
    |> validate_required([:text, :sent_at])
    |> validate_length(:text, min: 1)
    |> validate_length(:receivers, min: 1, message: "must contain at least one player")
    |> assoc_constraint(:sender)
    |> assoc_constraint(:conversation)
  end

  def open_conversation(sender, receivers, text) do
    participants = [sender|receivers]

    case Conversation.find_by_participants(participants) do
      {:ok, conversation} ->
        continue_conversation(sender, conversation, text)
      _ ->
        sent_at = LaFamiglia.DateTime.now
        # `receivers` is of type `{:array, :map}`, and thus does not accept
        # structs.
        receivers = for r <- receivers, do: %{id: r.id}

        conversation_changeset =
          Conversation.create(%{participants: participants, last_message_sent_at: sent_at})

        changeset(%Message{}, %{receivers: receivers, text: text, sent_at: sent_at})
        |> put_assoc(:sender, sender)
        |> put_assoc(:conversation, conversation_changeset)
    end
  end

  def continue_conversation(sender, conversation, text) do
    sent_at = LaFamiglia.DateTime.now

    conversation_changeset =
      conversation
      |> change_conversation
      |> put_change(:last_message_sent_at, sent_at)

    changeset(%Message{}, %{text: text, sent_at: sent_at})
    |> put_assoc(:sender, sender)
    |> put_assoc(:conversation, conversation_changeset)
  end

  defp change_conversation(conversation) do
    conversation = Repo.preload(conversation, [:participants, :conversation_statuses])

    new_participants =
      for s <- conversation.conversation_statuses do
        participant = Enum.find(conversation.participants, fn p -> p.id == s.player_id end)

        if s.read_until == conversation.last_message_sent_at do
          change(participant, %{unread_conversations: participant.unread_conversations + 1})
        else
          change(participant)
        end
      end

    change(conversation)
    |> put_assoc(:participants, new_participants)
  end
end

defimpl Poison.Encoder, for: LaFamiglia.Message do
  def encode(%{id: id, text: text, sender: sender}, _options) do
    Poison.encode!(%{id: id, text: text,
                     sender: %{id: sender.id, name: sender.name}})
  end
end
