defmodule LaFamiglia.Message do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset
  alias Ecto.Multi

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Conversation
  alias LaFamiglia.ConversationStatus
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
    |> cast(params, [:sender_id, :text, :sent_at, :conversation_id, :receivers])
    |> validate_required([:sender_id, :text, :sent_at])
    |> validate_length(:text, min: 1)
    |> validate_length(:receivers, min: 1, message: "must contain at least one player")
    |> assoc_constraint(:sender)
    |> assoc_constraint(:conversation)
  end

  def open_conversation(sender, receivers, text) do
    participants = [%{id: sender.id}|receivers]

    case Conversation.find_by_participants(participants) do
      {:ok, conversation} ->
        continue_conversation(sender, conversation, text)
      _ ->
        conversation_changeset =
          Conversation.create(
            %{participants: participants,
              last_message_sent_at: LaFamiglia.DateTime.now})

        changeset(%Message{},
          %{sender_id: sender.id,
            receivers: receivers,
            text: text,
            sent_at: LaFamiglia.DateTime.now})
        |> put_assoc(:conversation, conversation_changeset)
    end
  end

  def continue_conversation(sender, conversation, text) do
    conversation_changeset =
      conversation
      |> change(%{last_message_sent_at: LaFamiglia.DateTime.now})

    changeset(%Message{},
      %{sender_id: sender.id,
        text: text,
        sent_at: LaFamiglia.DateTime.now})
    |> put_assoc(:conversation, conversation_changeset)
  end
end

defimpl Poison.Encoder, for: LaFamiglia.Message do
  def encode(%{id: id, text: text, sender: sender}, _options) do
    Poison.encode!(%{id: id, text: text,
                     sender: %{id: sender.id, name: sender.name}})
  end
end
