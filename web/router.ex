defmodule LaFamiglia.Router do
  use LaFamiglia.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :ingame do
    plug LaFamiglia.Plugs.Authentication, "/"
    plug LaFamiglia.Plugs.VillaLoader
    plug LaFamiglia.Plugs.VillaChecker
    plug LaFamiglia.Plugs.Timer
    plug LaFamiglia.Plugs.VillaProcessor
  end

  scope "/", LaFamiglia do
    pipe_through :browser # Use the default browser stack

    resources "/session", SessionController,
                          only: [ :create, :new, :delete ],
                          singleton: true

    scope "" do
      pipe_through :ingame

      resources "/players", PlayerController, only: [ :create, :new ]
      resources "/villas", VillaController, only: [ :index, :show ]
    end

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", LaFamiglia do
  #   pipe_through :api
  # end
end
