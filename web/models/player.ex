defmodule LaFamiglia.Player do
  use LaFamiglia.Web, :model

  alias Ecto.Multi

  alias Comeonin.Bcrypt

  alias LaFamiglia.Repo
  alias LaFamiglia.Player
  alias LaFamiglia.Villa
  alias LaFamiglia.Conversation
  alias LaFamiglia.ConversationStatus
  alias LaFamiglia.Report

  schema "players" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :hashed_password, :string

    field :name, :string
    field :points, :integer

    field :unread_conversations, :integer, default: 0

    has_many :villas, Villa

    has_many :attack_movements, through: [:villas, :attack_movements]
    has_many :comeback_movements, through: [:villas, :comeback_movements]

    has_many :occupations, through: [:villas, :occupations]

    has_many :conversation_statuses, ConversationStatus
    many_to_many :conversations, Conversation, join_through: ConversationStatus

    has_many :reports, Report

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :password, :points])
    |> validate_required([:name, :email, :password])
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

  def recalc_points(player) do
    Multi.new
    |> Multi.run(:recalc_player_points, fn(_) ->
      player_points =
        from(v in assoc(player, :villas), select: sum(v.points))
        |> Repo.one

      from(p in Player, where: p.id == ^player.id)
      |> Repo.update_all(set: [points: player_points])

      {:ok, nil}
    end)
  end
end
