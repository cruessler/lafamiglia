defmodule LaFamiglia.Conversation do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Conversation
  alias LaFamiglia.Message
  alias LaFamiglia.ConversationStatus

  alias __MODULE__

  schema "conversations" do
    field :last_message_sent_at, :utc_datetime
    field :new_messages, :boolean, virtual: true

    has_many :messages, Message

    has_many :conversation_statuses, ConversationStatus
    many_to_many :participants, Player, join_through: ConversationStatus

    timestamps
  end

  def create(params) do
    participants =
      for p <- params.participants,
          do: change(p, %{unread_conversations: p.unread_conversations + 1})

    %Conversation{}
    |> cast(params, [:last_message_sent_at])
    |> put_assoc(:participants, participants)
  end

  @doc """
  Finds a conversation by its set of participants. Expects `participants` to
  contain only unique values.
  """
  def find_by_participants(participants) do
    # Find all conversations whose set of participants contains the players in
    # `participants`.
    conversation_ids =
      Enum.reduce(participants, from(c in Conversation, select: c.id), fn p, query ->
        from(c in query,
          join: s in ConversationStatus,
          on:
            s.conversation_id == c.id and
              s.player_id == ^p.id
        )
      end)
      |> Repo.all()

    if length(conversation_ids) > 0 do
      # Find the right conversation by the number of participants. This assumes
      # that, at any given time, every conversation is unique with respect to
      # its set of participants.
      conversation =
        from(c in Conversation,
          join: s in assoc(c, :conversation_statuses),
          group_by: c.id,
          select: %{id: c.id, participant_count: count(s.id)},
          where: c.id in ^conversation_ids
        )
        |> Repo.all()
        |> Enum.find(fn c -> c.participant_count == length(participants) end)

      unless is_nil(conversation), do: {:ok, Repo.get(Conversation, conversation.id)}
    end

    # Return nil if no conversation was found.
  end

  defp unread_conversations(statuses, last_message_sent_at),
    do: unread_conversations(statuses, last_message_sent_at, 0)

  defp unread_conversations([], _, acc), do: acc

  defp unread_conversations([first | rest], last_message_sent_at, acc) do
    read_until = get_field(first, :read_until)

    case DateTime.compare(read_until, last_message_sent_at) do
      :lt -> unread_conversations(rest, acc + 1)
      _ -> unread_conversations(rest, acc)
    end
  end

  @doc """
  Updates the associated `ConversationStatus` of a given `conversation` as well
  as the `player`’s `unread_conversations`.

  Returns a changeset for `player`.
  """
  def update_read_until_for(%{id: player_id} = player, conversation) do
    player = Repo.preload(player, conversation_statuses: :conversation)

    new_statuses =
      for s <- player.conversation_statuses do
        case s.player_id do
          ^player_id -> change(s, %{read_until: conversation.last_message_sent_at})
          _ -> change(s)
        end
      end

    unread_conversations = unread_conversations(new_statuses, conversation.last_message_sent_at)

    change(player, %{unread_conversations: unread_conversations})
    |> put_assoc(:conversation_statuses, new_statuses)
  end
end
