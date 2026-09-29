defmodule AttendanceTrackerWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AttendanceTrackerWeb, :html

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

  def app(assigns) do
    ~H"""
    <header class="sticky top-0 z-40 border-b border-base-300 bg-base-100/90 backdrop-blur">
      <div class="navbar mx-auto max-w-7xl gap-2 px-4 sm:px-6 lg:px-8">
        <div class="flex-1">
          <a href="/" class="flex w-fit items-center gap-2 text-lg font-bold tracking-tight">
            <.icon name="hero-clipboard-document-check" class="size-6" /> AttendanceTracker
          </a>
        </div>

        <nav class="hidden items-center gap-1 lg:flex">
          <.link navigate={~p"/"} class="btn btn-ghost">Check-in</.link>
          <.link :if={@admin_mode} navigate={~p"/participants"} class="btn btn-ghost">
            Participants
          </.link>
          <.link :if={@admin_mode} navigate={~p"/training_days"} class="btn btn-ghost">
            Training days
          </.link>
          <.link :if={@admin_mode} navigate={~p"/reporting"} class="btn btn-ghost">
            Reporting
          </.link>
          <.link :if={@admin_mode} navigate={~p"/admin"} class="btn btn-ghost">Admin</.link>
          <.link :if={!@admin_mode} navigate={~p"/login"} id="admin-mode-menu" class="btn btn-ghost">
            <.icon name="hero-lock-closed" class="size-4" /> Admin mode
          </.link>
          <.link
            :if={@admin_mode}
            href={~p"/logout"}
            method="delete"
            id="exit-admin-mode-menu"
            class="btn btn-ghost"
          >
            <.icon name="hero-lock-open" class="size-4" /> Exit admin mode
          </.link>
          <.theme_toggle />
        </nav>

        <details class="dropdown dropdown-end lg:hidden">
          <summary class="btn btn-ghost btn-square" aria-label="Open menu">
            <.icon name="hero-bars-3" class="size-6" />
          </summary>
          <ul class="menu dropdown-content z-50 mt-2 w-60 rounded-box border border-base-300 bg-base-100 p-2 shadow-xl">
            <li>
              <.link navigate={~p"/"}><.icon name="hero-home" class="size-5" /> Check-in</.link>
            </li>
            <li :if={@admin_mode}>
              <.link navigate={~p"/participants"}>
                <.icon name="hero-user-group" class="size-5" /> Participants
              </.link>
            </li>
            <li :if={@admin_mode}>
              <.link navigate={~p"/training_days"}>
                <.icon name="hero-calendar-days" class="size-5" /> Training days
              </.link>
            </li>
            <li :if={@admin_mode}>
              <.link navigate={~p"/reporting"}>
                <.icon name="hero-chart-bar" class="size-5" /> Reporting
              </.link>
            </li>
            <li :if={@admin_mode}>
              <.link navigate={~p"/admin"}>
                <.icon name="hero-cog-6-tooth" class="size-5" /> Admin
              </.link>
            </li>
            <li :if={!@admin_mode}>
              <.link navigate={~p"/login"}>
                <.icon name="hero-lock-closed" class="size-5" /> Admin mode
              </.link>
            </li>
            <li :if={@admin_mode}>
              <.link href={~p"/logout"} method="delete">
                <.icon name="hero-lock-open" class="size-5" /> Exit admin mode
              </.link>
            </li>
            <li class="mt-1 border-t border-base-300 pt-1">
              <div class="flex items-center justify-between gap-2 px-2 py-1">
                <span class="text-sm opacity-70">Theme</span>
                <.theme_toggle />
              </div>
            </li>
          </ul>
        </details>
      </div>
    </header>

    <main class="px-4 py-6 sm:px-6 sm:py-10 lg:px-8">
      <div class="mx-auto max-w-5xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
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
        title="We can't find the internet"
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
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
