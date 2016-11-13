defmodule LaFamiglia.Router do
  use LaFamiglia.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug LaFamiglia.Plugs.AssignDefaults
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug :fetch_session
    plug :protect_from_forgery
  end

  pipeline :ingame do
    plug LaFamiglia.Plugs.Authentication, "/"
    plug LaFamiglia.Plugs.Timer
    plug LaFamiglia.Plugs.VillaLoader
    plug LaFamiglia.Plugs.VillaChecker
    plug LaFamiglia.Plugs.VillaProcessor
  end

  scope "/", LaFamiglia do
    pipe_through :browser # Use the default browser stack

    resources "/session", SessionController,
                          only: [ :create, :new, :delete ],
                          singleton: true

    resources "/players", PlayerController, only: [ :create, :new ]

    scope "/" do
      pipe_through :ingame

      scope "/players" do
        get "/search/:query", PlayerController, :search
      end

      resources "/players", PlayerController, only: [ :index ]

      resources "/villas", VillaController, only: [ :index, :show ] do
        resources "/building_queue_items", BuildingQueueItemController, only: [ :create ]
        resources "/unit_queue_items", UnitQueueItemController, only: [ :create ]
        resources "/attack_movements", AttackMovementController, only: [ :new, :create ]

        resources "/reports", ReportController, only: [ :index ]
      end

      resources "/building_queue_items", BuildingQueueItemController, only: [ :delete ]
      resources "/unit_queue_items", UnitQueueItemController, only: [ :delete ]

      resources "/movements", MovementController, only: [ :index ]

      resources "/conversations", ConversationController, only: [ :index, :show ] do
        resources "/messages", MessageController, only: [ :create ]
      end
      resources "/messages", MessageController, only: [ :create ]
      resources "/reports", ReportController, only: [ :index, :show ]

      get "/map/:x/:y", MapController, :show

      get "/help", HelpController, :index
    end

    get "/", PageController, :index
  end

  scope "/api/v1", LaFamiglia.Api do
    pipe_through :api

    scope "/" do
      pipe_through :ingame

      get "/map", MapController, :show
    end
  end
end
