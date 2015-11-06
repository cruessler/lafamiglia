defmodule LaFamiglia.Conversation do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset

  alias LaFamiglia.Repo

  alias LaFamiglia.Message
  alias LaFamiglia.ConversationStatus

  schema "conversations" do
    has_many :messages, Message

    has_many :conversation_statuses, ConversationStatus
    has_many :players, through: [:conversation_statuses, :player]

    field :participants, {:array, :map}, virtual: true

    timestamps
  end

  after_insert :create_conversation_statuses

  @required_fields ~w(participants)
  @optional_fields ~w(messages)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def create_conversation_statuses(changeset) do
    # The association has to be preloaded as otherwise an exception is thrown.
    conversation = changeset.model |> Repo.preload(:conversation_statuses)

    statuses =
      for p <- changeset.changes.participants do
        Ecto.Model.build(conversation, :conversation_statuses, %{player_id: p.id})
        |> Repo.insert!
      end

    Changeset.put_change(%Changeset{changeset | model: conversation},
      :conversation_statuses, statuses)
  end
end
