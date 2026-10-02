defmodule AttendanceTrackerWeb.Router do
  use AttendanceTrackerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AttendanceTrackerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AttendanceTrackerWeb.Plugs.SetLocale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug AttendanceTrackerWeb.Plugs.RequireAdminPin
  end

  pipeline :kiosk do
    plug AttendanceTrackerWeb.Plugs.RequireKioskSession
  end

  scope "/", AttendanceTrackerWeb do
    pipe_through :browser

    live "/start", SessionUnlockLive, :new
    post "/start", SessionController, :start

    live "/login", LoginLive, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete

    get "/photos/:id/:version", PhotoController, :show
    get "/manifest.webmanifest", PwaController, :manifest
    get "/locale/:locale", LocaleController, :update
  end

  scope "/", AttendanceTrackerWeb do
    pipe_through [:browser, :kiosk]

    live "/", CheckInLive, :index
  end

  scope "/", AttendanceTrackerWeb do
    pipe_through [:browser, :authenticated]

    live "/participants", ParticipantLive.Index, :index
    live "/participants/new", ParticipantLive.Form, :new
    live "/participants/:id", ParticipantLive.Show, :show
    live "/participants/:id/edit", ParticipantLive.Form, :edit

    live "/training", TrainingLive.Index, :index
    live "/training/new", TrainingLive.Form, :new
    live "/training/:id/edit", TrainingLive.Form, :edit

    live "/reporting", ReportLive, :index
    get "/reporting/download", ReportController, :download

    live "/admin", AdminLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AttendanceTrackerWeb do
  #   pipe_through :api
  # end
end
