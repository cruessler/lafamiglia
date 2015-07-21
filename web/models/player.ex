defmodule LaFamiglia.Player do
  use LaFamiglia.Web, :model
  alias LaFamiglia.Repo
  alias Comeonin.Bcrypt

  schema "players" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :hashed_password, :string

    field :name, :string
    field :points, :integer

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
    |> validate_unique(:name, on: Repo)
    |> validate_format(:email, ~r/@/)
    |> validate_unique(:email, on: Repo)
    |> encrypt_password
  end

  def encrypt_password(changeset) do
    %{ changes: changes } = changeset

    if Map.has_key?(changes, :password) do
      hashed_password = Map.get(changes, :password) |> Bcrypt.hashpwsalt
      %{ changeset | changes: changes
                              |> Map.delete(:password)
                              |> Map.put(:hashed_password, hashed_password) }
    else
      changeset
    end
  end
end
