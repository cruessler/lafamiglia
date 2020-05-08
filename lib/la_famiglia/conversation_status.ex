defmodule LaFamiglia.ConversationStatus do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Player
  alias LaFamiglia.Conversation

  schema "conversation_statuses" do
    belongs_to :player, Player
    belongs_to :conversation, Conversation

    field :read_until, :utc_datetime

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [])
    |> assoc_constraint(:player)
    |> assoc_constraint(:conversation)
  end
end
