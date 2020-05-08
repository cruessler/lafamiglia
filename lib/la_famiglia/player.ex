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

    # `on_replace: :nilify` allows for `put_assoc :villas, [])` to be used in
    # tests.
    has_many :villas, Villa, on_replace: :nilify

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
    %{changes: changes} = changeset

    if Map.has_key?(changes, :password) do
      hashed_password = changes.password |> Bcrypt.hashpwsalt()

      changeset
      |> delete_change(:password)
      |> put_change(:hashed_password, hashed_password)
    else
      changeset
    end
  end

  def recalc_points(players) when is_list(players) do
    ids = for p <- players, do: p.id

    Multi.new()
    |> Multi.run(:recalc_player_points, fn _, _ ->
      from(p in Player,
        update: [
          set: [
            points:
              fragment("(SELECT SUM(v.points) FROM villas AS v WHERE v.player_id = ?)", p.id)
          ]
        ],
        where: p.id in ^ids
      )
      |> Repo.update_all([])

      # Players having 0 villas will have `NULL` points after the previous
      # query. Their points have to explicitly be set to `0` by the following
      # query.
      from(p in Player,
        update: [set: [points: 0]],
        where: p.id in ^ids and is_nil(p.points)
      )
      |> Repo.update_all([])

      {:ok, nil}
    end)
  end

  def recalc_points(%Player{} = player), do: recalc_points([player])
end
