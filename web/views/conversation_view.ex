defmodule LaFamiglia.ConversationView do
  use LaFamiglia.Web, :view

  def player_select(%{name: name}, field) do
    content_tag :div, "", name: "#{name}[#{field}]", class: "player-select"
  end
end
