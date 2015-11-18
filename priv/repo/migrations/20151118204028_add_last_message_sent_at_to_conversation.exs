defmodule LaFamiglia.Repo.Migrations.AddLastMessageSentAtToConversation do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :last_message_sent_at, :datetime
    end
  end
end
