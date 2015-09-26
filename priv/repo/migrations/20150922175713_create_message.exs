defmodule LaFamiglia.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :conversation_id, references(:conversations)
      add :sender_id, references(:players)

      add :text, :string

      timestamps
    end
  end
end
