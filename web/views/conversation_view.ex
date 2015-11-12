defmodule LaFamiglia.ConversationView do
  use LaFamiglia.Web, :view

  def li_class_for(conversation, shown_conversation) do
    if shown_conversation.id == conversation.id do
      "selected"
    end
  end

  def participants_except(participants, except) do
    participants
    |> Enum.filter(fn(p) -> p.id != except.id end)
    |> Enum.map(fn(p) -> p.name end)
    |> Enum.join(", ")
  end
end
