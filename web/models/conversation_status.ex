defmodule LaFamiglia.ConversationStatus do
  use LaFamiglia.Web, :model

  alias Ecto.Multi

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Conversation

  schema "conversation_statuses" do
    belongs_to :player, Player
    belongs_to :conversation, Conversation

    field :read_until, Ecto.DateTime

    timestamps
  end

  @required_fields ~w()
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> assoc_constraint(:player)
    |> assoc_constraint(:conversation)
  end

  def update_read_until(conversation, player) do
    query =
      from(s in assoc(conversation, :conversation_statuses),
        where: s.player_id == ^player.id)
    updates = [set: [read_until: conversation.last_message_sent_at]]

    Multi.new
    |> Multi.update_all(:update_read_until, query, updates)
  end
end
