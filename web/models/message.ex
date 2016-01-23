defmodule LaFamiglia.Message do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Conversation
  alias LaFamiglia.ConversationStatus

  schema "messages" do
    belongs_to :sender, Player
    belongs_to :conversation, Conversation

    field :text, :string

    field :receivers, {:array, :map}, virtual: true

    timestamps
  end

  before_insert :find_or_create_conversation
  after_insert :update_conversation

  @required_fields ~w(sender_id receivers text)
  @optional_fields ~w(conversation_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:text, min: 1)
    |> remove_sender_from_receivers
    |> validate_receivers
    |> assoc_constraint(:sender)
    |> assoc_constraint(:conversation)
  end

  defp remove_sender_from_receivers(
    %Changeset{changes: %{sender_id: sender_id, receivers: receivers}} = changeset) do

    new_receivers = Enum.filter receivers, fn(r) ->
      r.id != sender_id
    end

    put_change(changeset, :receivers, new_receivers)
  end
  defp remove_sender_from_receivers(%Changeset{} = changeset), do: changeset

  # Since `conversation_id` is checked through `assoc_constraint` and every
  # Conversation is assumed to be valid, a changeset containing a
  # `conversation_id` does not need to be double checked.
  defp validate_receivers(%Changeset{changes: %{conversation_id: _}} = changeset) do
    changeset
  end
  defp validate_receivers(%Changeset{changes: %{receivers: [_|_]}} = changeset) do
    changeset
  end
  defp validate_receivers(%Changeset{} = changeset) do
    changeset
    |> add_error(:receivers, "must contain at least one player")
  end

  defp find_conversation(%Changeset{changes: %{receivers: receivers} = changes}) do
    query        = from(c in Conversation, select: c.id)
    participants = [%{id: changes.sender_id}|receivers]

    # Find all conversations whose set of participants contains the players in
    # `participants`.
    conversation_ids =
      Enum.reduce(participants, query, fn(p, query) ->
        from(c in query,
          join: s in ConversationStatus, on: s.conversation_id == c.id
                                             and s.player_id == ^p.id)
      end)
      |> Repo.all

    if length(conversation_ids) > 0 do
      # Find the right conversation by the number of participants. This assumes
      # that, at any given time, every conversation is unique with respect to
      # its set of participants.
      from(c in Conversation,
        join: s in assoc(c, :conversation_statuses),
        group_by: c.id,
        select: %{id: c.id, participant_count: count(s.id)},
        where: c.id in ^conversation_ids)
      |> Repo.all
      |> Enum.find(fn(c) -> c.participant_count == length(participants) end)
    end
    # Return nil if no conversation was found.
  end

  defp find_or_create_conversation(%Changeset{changes: changes} = changeset) do
    if changes.conversation_id do
      changeset
    else
      conversation = case find_conversation(changeset) do
        nil ->
          Conversation.changeset(%Conversation{},
            %{participants: [%{id: changes.sender_id}|changes.receivers]})
          |> Repo.insert!
        conversation ->
          conversation
      end

      changeset
      |> put_change(:conversation_id, conversation.id)
    end
  end

  defp update_conversation(%Changeset{model: message} = changeset) do
    assoc(message, :conversation)
    |> Repo.one
    |> Changeset.change(%{last_message_sent_at: message.inserted_at})
    |> Repo.update!

    changeset
  end
end

defimpl Poison.Encoder, for: LaFamiglia.Message do
  def encode(%{id: id, text: text, sender: sender}, _options) do
    Poison.encode!(%{id: id, text: text,
                     sender: %{id: sender.id, name: sender.name}})
  end
end
