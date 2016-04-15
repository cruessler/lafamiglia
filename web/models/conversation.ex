defmodule LaFamiglia.Conversation do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset
  alias Ecto.Multi

  alias LaFamiglia.Repo

  alias LaFamiglia.Conversation
  alias LaFamiglia.Message
  alias LaFamiglia.ConversationStatus

  schema "conversations" do
    field :last_message_sent_at, Ecto.DateTime
    field :new_messages, :boolean, virtual: true

    has_many :messages, Message

    has_many :conversation_statuses, ConversationStatus
    has_many :players, through: [:conversation_statuses, :player]

    field :participants, {:array, :map}, virtual: true

    timestamps
  end

  def create(params) do
    changeset =
      change(%__MODULE__{})
      |> put_change(:participants, params.participants)

    Multi.new
    |> Multi.insert(:conversation, changeset)
    |> Multi.run(:create_statuses, fn
      %{conversation: conversation} -> {:ok, create_conversation_statuses(conversation)}
    end)
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

      unless is_nil(conversation), do: {:ok, conversation}
    end
    # Return nil if no conversation was found.
  end

  @required_fields ~w(participants)
  @optional_fields ~w(messages last_message_sent_at)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def create_conversation_statuses(conversation) do
    # The association has to be preloaded as otherwise an exception is thrown.
    conversation = conversation |> Repo.preload(:conversation_statuses)

    statuses =
      Enum.map conversation.participants, fn(p) ->
        Ecto.build_assoc(conversation, :conversation_statuses, %{player_id: p.id})
      end

    conversation
    |> change
    |> put_assoc(:conversation_statuses, statuses)
    |> Repo.update!
  end
end
