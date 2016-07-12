defmodule LaFamiglia.Conversation do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset
  alias Ecto.Multi

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Conversation
  alias LaFamiglia.Message
  alias LaFamiglia.ConversationStatus

  alias __MODULE__

  schema "conversations" do
    field :last_message_sent_at, Ecto.DateTime
    field :new_messages, :boolean, virtual: true

    has_many :messages, Message

    has_many :conversation_statuses, ConversationStatus
    many_to_many :participants, Player, join_through: ConversationStatus

    timestamps
  end

  def create(params) do
    participants =
      for p <- params.participants,
        do: Changeset.change(p, %{unread_conversations: p.unread_conversations + 1})

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
      Enum.reduce(participants, from(c in Conversation, select: c.id), fn(p, query) ->
        from(c in query,
          join: s in ConversationStatus,
            on: s.conversation_id == c.id
                and s.player_id == ^p.id)
      end)
      |> Repo.all

    if length(conversation_ids) > 0 do
      # Find the right conversation by the number of participants. This assumes
      # that, at any given time, every conversation is unique with respect to
      # its set of participants.
      conversation = from(c in Conversation,
        join: s in assoc(c, :conversation_statuses),
        group_by: c.id,
        select: %{id: c.id, participant_count: count(s.id)},
        where: c.id in ^conversation_ids)
      |> Repo.all
      |> Enum.find(fn(c) -> c.participant_count == length(participants) end)

      unless is_nil(conversation), do: {:ok, Repo.get(Conversation, conversation.id)}
    end
    # Return nil if no conversation was found.
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:participants, :messages, :last_message_sent_at])
    |> validate_required([:participants])
  end
end
