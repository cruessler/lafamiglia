defmodule LaFamiglia.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use LaFamiglia.Web, :controller
      use LaFamiglia.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      # FIXME: As soon as the deprecated callbacks have been replaced by a
      # superior alternative, `use Eco.Model` has to be changed to `import
      # Ecto`.
      # http://www.phoenixframework.org/v1.0.0/blog/upgrading-from-v10-to-v11
      use Ecto.Model
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      # Alias the data repository and import query/model functions
      alias LaFamiglia.Repo
      import Ecto
      import Ecto.Query, only: [from: 2]

      # Import URL helpers from the router
      import LaFamiglia.Router.Helpers
      import LaFamiglia.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Import URL helpers from the router
      import LaFamiglia.Router.Helpers

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import LaFamiglia.ErrorHelpers
      import LaFamiglia.Gettext

      alias LaFamiglia.Building
      alias LaFamiglia.Unit

      alias LaFamiglia.Villa

      import LaFamiglia.AppView
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      # Alias the data repository and import query/model functions
      alias LaFamiglia.Repo
      import Ecto
      import Ecto.Query, only: [from: 2]
      import LaFamiglia.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
