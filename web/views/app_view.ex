defmodule LaFamiglia.AppView do
  alias LaFamiglia.Villa

  use Phoenix.HTML

  def coordinates(%Villa{x: x, y: y}) do
    "#{x}|#{y}"
  end
  def coordinates(_) do
    ""
  end

  def resources(%{resource_1: resource_1, resource_2: resource_2, resource_3: resource_3}) do
    content_tag :div, class: "resources" do
      "R1: #{resource_1}, R2: #{resource_2}, R3: #{resource_3}"
    end
  end
  def resources(_) do
    ""
  end

  def react_component(class, props \\ %{}) do
    data_attributes =
      [ "data-react-class": class,
        "data-react-props": html_escape(Poison.encode!(props)) ]

    content_tag(:div, "", data_attributes)
  end
end
