defmodule LaFamiglia.Player do
  use LaFamiglia.Web, :model

  alias Comeonin.Bcrypt

  alias LaFamiglia.Villa
  alias LaFamiglia.ConversationStatus

  schema "players" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :hashed_password, :string

    field :name, :string
    field :points, :integer

    has_many :villas, Villa

    has_many :conversation_statuses, ConversationStatus
    has_many :conversations, through: [:conversation_statuses, :conversation]

    timestamps
  end

  @required_fields ~w(name email password)
  @optional_fields ~w(points)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_length(:password_confirmation, min: 8)
    |> validate_confirmation(:password)
    |> validate_length(:name, min: 3, max: 32)
    |> unique_constraint(:name)
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> encrypt_password
  end

  def encrypt_password(changeset) do
    %{ changes: changes } = changeset

    if Map.has_key?(changes, :password) do
      hashed_password = changes.password |> Bcrypt.hashpwsalt

      changeset
      |> delete_change(:password)
      |> put_change(:hashed_password, hashed_password)
    else
      changeset
    end
  end
end
