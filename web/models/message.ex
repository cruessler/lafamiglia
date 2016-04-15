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

    field :receivers, {:array, :map}, virtual: true

    timestamps
  end

  @required_fields ~w(sender_id text)
  @optional_fields ~w(conversation_id receivers)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
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
        changeset =
          changeset(%Message{},
            %{sender_id: sender.id,
              receivers: receivers,
              text: text})
        conversation_multi =
          Conversation.create(%{participants: participants})

        Multi.new
        |> Multi.append(conversation_multi)
        |> Multi.run(:message, fn(%{conversation: conversation}) ->
          changeset
          |> put_change(:conversation_id, conversation.id)
          |> Repo.insert
        end)
        |> Multi.run(:update_conversation, fn(%{message: message}) ->
           {:ok, update_conversation(message)}
        end)
    end
  end

  def continue_conversation(sender, conversation, text) do
    changeset =
      changeset(%Message{},
        %{sender_id: sender.id,
          conversation_id: conversation.id,
          text: text})

    Multi.new
    |> Multi.insert(:message, changeset)
    |> Multi.run(:update_conversation, fn(%{message: message}) ->
       {:ok, update_conversation(message)}
    end)
  end

  defp update_conversation(message) do
    assoc(message, :conversation)
    |> Repo.one
    |> change(%{last_message_sent_at: message.inserted_at})
    |> Repo.update!
  end
end

defimpl Poison.Encoder, for: LaFamiglia.Message do
  def encode(%{id: id, text: text, sender: sender}, _options) do
    Poison.encode!(%{id: id, text: text,
                     sender: %{id: sender.id, name: sender.name}})
  end
end
