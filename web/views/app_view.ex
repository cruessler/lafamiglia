defmodule LaFamiglia.AppView do
  alias LaFamiglia.Villa

  use Phoenix.HTML

  def coordinates(%Villa{x: x, y: y}), do: "#{x}|#{y}"
  def coordinates(_), do: ""

  def resources(%{resource_1: resource_1, resource_2: resource_2, resource_3: resource_3}) do
    content_tag :span, class: "resources" do
      "R1: #{trunc resource_1}, R2: #{trunc resource_2}, R3: #{trunc resource_3}"
    end
  end
  def resources(_), do: ""

  def unread_conversations_badge(%{unread_conversations: unread_conversations})
    when unread_conversations > 0
  do
    content_tag :span, class: "badge" do "#{unread_conversations}" end
  end
  def unread_conversations_badge(_), do: ""

  def player_select(%{name: name}, field) do
    react_component "PlayerSelector", %{name: "#{name}[#{field}]"},
                                      [class: "player-select"]
  end

  def react_component(class, props \\ %{}, attrs \\ []) do
    {tag, attrs} = Keyword.pop(attrs, :tag, :div)
    data_attributes =
      [ "data-react-class": class,
        "data-react-props": html_escape(Poison.encode!(props)) ]

    content_tag(tag, "", Dict.merge(attrs, data_attributes))
  end
end
