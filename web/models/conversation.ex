defmodule LaFamiglia.Conversation do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Message
  alias LaFamiglia.ConversationStatus

  schema "conversations" do
    has_many :messages, Message

    has_many :conversation_statuses, ConversationStatus
    has_many :players, through: [:conversation_statuses, :player]

    timestamps
  end

  @required_fields ~w()
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
end
