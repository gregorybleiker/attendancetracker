defmodule AttendanceTrackerWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AttendanceTrackerWeb, :html

  alias AttendanceTrackerWeb.Locales

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  attr :admin_mode, :boolean,
    default: false,
    doc: "whether the session is in admin mode (toggles the admin menu item)"

  slot :inner_block, required: true

  slot :header,
    doc: "optional toolbar content rendered in the app header, right-aligned"

  slot :menu, doc: "optional extra entries rendered in the left flyout menu"

  def app(assigns) do
    assigns =
      assigns
      |> assign(:locale, Gettext.get_locale(AttendanceTrackerWeb.Gettext))
      |> assign(:drawer_open, open_drawer())
      |> assign(:drawer_close, close_drawer())

    ~H"""
    <header class="sticky top-0 z-40 border-b border-base-300 bg-base-100/90 backdrop-blur">
      <div class="navbar mx-auto min-h-0 max-w-5xl gap-2 px-4 py-1 sm:px-6 lg:px-8">
        <div class="flex flex-1 items-center gap-1">
          <button
            type="button"
            id="menu-toggle"
            phx-click={@drawer_open}
            class="btn btn-ghost btn-square btn-sm"
            aria-label={gettext("Open menu")}
          >
            <.icon name="hero-bars-3" class="size-5" />
          </button>
          <a href="/" class="flex w-fit items-center gap-2 text-base font-bold tracking-tight">
            <.logo class="size-5" /> AttendanceTracker
          </a>
        </div>

        <div :if={@header != []} class="flex items-center gap-2">
          {render_slot(@header)}
        </div>
      </div>
    </header>

    <div
      id="nav-overlay"
      data-open="false"
      class="group pointer-events-none fixed inset-0 z-50 opacity-0 transition-opacity duration-200 data-[open=true]:pointer-events-auto data-[open=true]:opacity-100"
    >
      <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" phx-click={@drawer_close}></div>

      <aside
        id="nav-drawer"
        inert
        class="absolute inset-y-0 left-0 flex w-72 max-w-[85vw] -translate-x-full flex-col border-r border-base-300 bg-base-100 shadow-2xl transition-transform duration-300 ease-out group-data-[open=true]:translate-x-0"
      >
        <div class="flex items-center justify-between border-b border-base-300 px-4 py-3">
          <a href="/" class="flex items-center gap-2 text-lg font-bold tracking-tight">
            <.logo class="size-6" /> AttendanceTracker
          </a>
          <button
            type="button"
            phx-click={@drawer_close}
            class="btn btn-ghost btn-square btn-sm"
            aria-label={gettext("Close menu")}
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>

        <nav class="flex flex-1 flex-col gap-1 overflow-y-auto p-3">
          <.drawer_link navigate={~p"/"} icon="hero-home">{gettext("Check-in")}</.drawer_link>
          <.drawer_link navigate={~p"/event-check-in"} icon="hero-ticket">
            {gettext("Event check-in")}
          </.drawer_link>
          {render_slot(@menu)}

          <div :if={@admin_mode} class="my-2 border-t border-base-300"></div>

          <.drawer_link :if={@admin_mode} navigate={~p"/participants"} icon="hero-user-group">
            {gettext("Participants")}
          </.drawer_link>
          <.drawer_link :if={@admin_mode} navigate={~p"/training"} icon="hero-calendar-days">
            {gettext("Training")}
          </.drawer_link>
          <.drawer_link :if={@admin_mode} navigate={~p"/events"} icon="hero-ticket">
            {gettext("Events")}
          </.drawer_link>
          <.drawer_link :if={@admin_mode} navigate={~p"/reporting"} icon="hero-chart-bar">
            {gettext("Reporting")}
          </.drawer_link>
          <.drawer_link :if={@admin_mode} navigate={~p"/admin"} icon="hero-cog-6-tooth">
            {gettext("Admin")}
          </.drawer_link>
          <.drawer_link
            :if={@admin_mode}
            navigate={~p"/admin/infos"}
            icon="hero-presentation-chart-bar"
          >
            {gettext("Info screen")}
          </.drawer_link>

          <div class="my-2 border-t border-base-300"></div>

          <.link
            :if={!@admin_mode}
            navigate={~p"/login"}
            id="admin-mode-menu"
            class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-base-content/80 transition-colors hover:bg-base-200 hover:text-base-content"
          >
            <.icon name="hero-lock-closed" class="size-5" /> {gettext("Admin mode")}
          </.link>
          <.link
            :if={@admin_mode}
            href={~p"/logout"}
            method="delete"
            id="exit-admin-mode-menu"
            class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-base-content/80 transition-colors hover:bg-base-200 hover:text-base-content"
          >
            <.icon name="hero-lock-open" class="size-5" /> {gettext("Exit admin mode")}
          </.link>
        </nav>

        <div class="space-y-3 border-t border-base-300 p-3">
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm opacity-70">{gettext("Language")}</span>
            <.language_toggle locale={@locale} id="language-toggle-drawer" />
          </div>
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm opacity-70">{gettext("Theme")}</span>
            <.theme_toggle />
          </div>
        </div>
      </aside>
    </div>

    <main class="px-4 py-6 sm:px-6 sm:py-10 lg:px-8">
      <div class="mx-auto max-w-5xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  defp open_drawer do
    JS.set_attribute({"data-open", "true"}, to: "#nav-overlay")
    |> JS.remove_attribute("inert", to: "#nav-drawer")
  end

  defp close_drawer do
    JS.set_attribute({"data-open", "false"}, to: "#nav-overlay")
    |> JS.set_attribute({"inert", ""}, to: "#nav-drawer")
  end

  attr :navigate, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  @doc """
  A single navigation entry inside the left flyout menu.
  """
  def drawer_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-base-content/80 transition-colors hover:bg-base-200 hover:text-base-content"
    >
      <.icon name={@icon} class="size-5" />
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :click, :any, required: true
  attr :id, :string, default: nil
  attr :icon, :string, required: true
  slot :inner_block, required: true

  @doc """
  A non-navigation action entry (e.g. a `JS` command) inside the left flyout
  menu, styled like `drawer_link/1`.
  """
  def drawer_button(assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      phx-click={@click}
      class="flex w-full cursor-pointer items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium text-base-content/80 transition-colors hover:bg-base-200 hover:text-base-content"
    >
      <.icon name={@icon} class="size-5" />
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :class, :string, default: "size-6"

  @doc """
  The app logo: two people, the back one faded and the front one solid.

  Uses `currentColor`, so it follows the surrounding text colour (and thus the
  light/dark theme).
  """
  def logo(assigns) do
    ~H"""
    <svg viewBox="6 15 53 42" fill="currentColor" aria-hidden="true" class={@class}>
      <g opacity="0.45">
        <circle cx="21" cy="25" r="7" />
        <path d="M 9 48 A 12 14 0 0 1 33 48 Z" />
      </g>
      <g>
        <circle cx="42" cy="29" r="8.5" />
        <path d="M 28 54 A 14 15 0 0 1 56 54 Z" />
      </g>
    </svg>
    """
  end

  attr :locale, :string, required: true
  attr :id, :string, default: "language-toggle"

  @doc """
  Language switcher: a link per available locale that stores the choice in the
  session and reloads the page.
  """
  def language_toggle(assigns) do
    ~H"""
    <div class="join" id={@id}>
      <.link
        :for={locale <- Locales.all()}
        href={~p"/locale/#{locale}"}
        class={["btn btn-ghost btn-sm join-item", @locale == locale && "btn-active"]}
      >
        {String.upcase(locale)}
      </.link>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
