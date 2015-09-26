defmodule LaFamiglia.Message do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset

  alias LaFamiglia.Repo

  alias LaFamiglia.Conversation

  schema "messages" do
    belongs_to :sender, Player
    belongs_to :conversation, Conversation

    field :text, :string

    field :receivers, {:array, :map}, virtual: true

    timestamps
  end

  before_insert :create_conversation

  @required_fields ~w(sender_id receivers text)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:text, min: 1)
    |> validate_receivers
    |> assoc_constraint(:sender)
    |> assoc_constraint(:conversation)
  end

  # Ecto removes empty lists in `cast`. If `receivers` is present it contains at
  # least one element.
  defp validate_receivers(%Changeset{changes: %{receivers: receivers}} = changeset)
       when is_list(receivers) do
    changeset
  end
  defp validate_receivers(%Changeset{} = changeset) do
    changeset
    |> add_error(:receivers, "must contain at least one player")
  end

  defp create_conversation(%Changeset{changes: changes} = changeset) do
    conversation =
      Conversation.changeset(%Conversation{}, %{})
      |> Repo.insert!

    changes.receivers ++ [%{id: changes.sender_id}] |> Enum.map fn(p) ->
      Ecto.Model.build(conversation, :conversation_statuses, %{ player_id: p.id })
      |> Repo.insert!
    end

    changeset
    |> put_change(:conversation_id, conversation.id)
  end
end
