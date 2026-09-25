defmodule AttendanceTrackerWeb.Router do
  use AttendanceTrackerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AttendanceTrackerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug AttendanceTrackerWeb.Plugs.RequireAdminPin
  end

  scope "/", AttendanceTrackerWeb do
    pipe_through :browser

    live "/", CheckInLive, :index

    live "/login", LoginLive, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  scope "/", AttendanceTrackerWeb do
    pipe_through [:browser, :authenticated]

    live "/participants", ParticipantLive.Index, :index
    live "/participants/new", ParticipantLive.Form, :new
    live "/participants/:id", ParticipantLive.Show, :show
    live "/participants/:id/edit", ParticipantLive.Form, :edit

    live "/training_days", TrainingDayLive.Index, :index
    live "/training_days/new", TrainingDayLive.Form, :new
    live "/training_days/:id/edit", TrainingDayLive.Form, :edit

    live "/reporting", ReportLive, :index
    get "/reporting/download", ReportController, :download

    live "/admin", AdminLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AttendanceTrackerWeb do
  #   pipe_through :api
  # end
end
