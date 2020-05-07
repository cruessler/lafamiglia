defmodule LaFamiglia.Repo.Migrations.AddLastMessageSentAtToConversation do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :last_message_sent_at, :utc_datetime
    end
  end
end
