defmodule AttendanceTrackerWeb.InfoComponents do
  @moduledoc """
  Components for the kiosk's full-screen info mode and the admin area's
  WYSIWYG rich-text editor.
  """
  use AttendanceTrackerWeb, :html

  attr :id, :string, required: true
  attr :name, :string, required: true, doc: "the form field name, e.g. \"info[body]\""
  attr :value, :string, default: ""

  @doc """
  A minimal contenteditable WYSIWYG editor.

  The rich-text HTML is kept in sync with a hidden input (`name`) by the
  `.WysiwygEditor` colocated hook, so it submits with the surrounding form.
  """
  def wysiwyg(assigns) do
    ~H"""
    <div id={@id} class="overflow-hidden rounded-lg border border-base-300 bg-base-100">
      <div
        data-wysiwyg-toolbar
        class="flex flex-wrap items-center gap-1 border-b border-base-300 bg-base-200/60 p-1.5"
      >
        <.wysiwyg_button cmd="bold" icon="hero-bold" title={gettext("Bold")} />
        <.wysiwyg_button cmd="italic" icon="hero-italic" title={gettext("Italic")} />
        <.wysiwyg_button cmd="underline" icon="hero-underline" title={gettext("Underline")} />
        <span class="mx-1 h-5 w-px bg-base-300"></span>
        <.wysiwyg_button cmd="formatBlock" arg="H1" icon="hero-h1" title={gettext("Heading 1")} />
        <.wysiwyg_button cmd="formatBlock" arg="H2" icon="hero-h2" title={gettext("Heading 2")} />
        <.wysiwyg_button cmd="formatBlock" arg="H3" icon="hero-h3" title={gettext("Heading 3")} />
        <.wysiwyg_button cmd="formatBlock" arg="P" label="P" title={gettext("Paragraph")} />
        <span class="mx-1 h-5 w-px bg-base-300"></span>
        <.wysiwyg_button
          cmd="insertUnorderedList"
          icon="hero-list-bullet"
          title={gettext("Bullet list")}
        />
        <.wysiwyg_button
          cmd="insertOrderedList"
          icon="hero-numbered-list"
          title={gettext("Numbered list")}
        />
        <.wysiwyg_button cmd="createLink" icon="hero-link" title={gettext("Insert link")} />
        <span class="mx-1 h-5 w-px bg-base-300"></span>
        <.wysiwyg_button cmd="removeFormat" icon="hero-x-mark" title={gettext("Clear formatting")} />
      </div>

      <div
        id={"#{@id}-editor"}
        contenteditable="true"
        role="textbox"
        aria-multiline="true"
        phx-hook=".WysiwygEditor"
        phx-update="ignore"
        data-wysiwyg-editor
        class="rich-text min-h-48 cursor-text p-3 text-base focus:outline-none"
      ></div>

      <textarea name={@name} data-wysiwyg-input class="hidden" aria-hidden="true">{@value}</textarea>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".WysiwygEditor">
      export default {
        mounted() {
          this.input = this.el.parentElement.querySelector("[data-wysiwyg-input]")
          this.toolbar = this.el.parentElement.querySelector("[data-wysiwyg-toolbar]")
          this.el.innerHTML = this.input.value || "<p><br></p>"

          this.sync = () => {
            this.input.value = this.el.innerHTML
          }

          this.el.addEventListener("input", this.sync)
          this.el.addEventListener("blur", this.sync)

          // Keep the selection/range when a toolbar button is pressed.
          this.toolbar.addEventListener("mousedown", event => event.preventDefault())

          this.toolbar.addEventListener("click", event => {
            const button = event.target.closest("[data-wysiwyg-cmd]")
            if (!button) return

            event.preventDefault()
            const command = button.dataset.wysiwygCmd
            let argument = button.dataset.wysiwygArg || null

            if (command === "createLink") {
              argument = window.prompt("URL")
              if (!argument) return
            }

            this.el.focus()
            document.execCommand(command, false, argument)
            this.sync()
          })
        }
      }
    </script>
    """
  end

  attr :cmd, :string, required: true
  attr :arg, :string, default: nil
  attr :icon, :string, default: nil
  attr :label, :string, default: nil
  attr :title, :string, required: true

  defp wysiwyg_button(assigns) do
    ~H"""
    <button
      type="button"
      data-wysiwyg-cmd={@cmd}
      data-wysiwyg-arg={@arg}
      title={@title}
      aria-label={@title}
      class="flex size-8 cursor-pointer items-center justify-center rounded-md text-base-content/80 transition-colors hover:bg-base-300 hover:text-base-content"
    >
      <.icon :if={@icon} name={@icon} class="size-4" />
      <span :if={!@icon} class="text-sm font-semibold">{@label}</span>
    </button>
    """
  end

  attr :infos, :list, required: true
  attr :idle_timeout_ms, :integer, required: true
  attr :rotation_ms, :integer, required: true

  @doc """
  The full-screen info mode shown on the kiosk after a stretch of inactivity.

  Slides rotate every `rotation_ms`; tapping anywhere on the screen dismisses
  the overlay and resets the idle timer.
  """
  def info_mode(assigns) do
    ~H"""
    <div
      :if={@infos != []}
      id="info-mode"
      phx-hook=".InfoMode"
      phx-update="ignore"
      data-idle-timeout={@idle_timeout_ms}
      data-rotation={@rotation_ms}
      class="fixed inset-0 z-[100] hidden bg-base-100"
    >
      <div class="flex h-full w-full items-center justify-center overflow-hidden p-8 lg:p-20">
        <div
          :for={info <- @infos}
          data-info-slide={info.id}
          class="hidden w-full max-w-4xl text-center"
        >
          <h1 :if={info.title} class="mb-6 text-4xl font-black tracking-tight lg:text-6xl">
            {info.title}
          </h1>
          <div class="rich-text mx-auto text-xl lg:text-3xl">{raw(info.body || "")}</div>
        </div>
      </div>

      <p class="absolute inset-x-0 bottom-6 text-center text-sm opacity-40">
        {gettext("Tap the screen to continue")}
      </p>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".InfoMode">
      export default {
        mounted() {
          this.idleMs = parseInt(this.el.dataset.idleTimeout, 10)
          this.rotationMs = parseInt(this.el.dataset.rotation, 10)
          this.active = false

          // Any activity while idle only resets the timer. While the overlay is
          // shown we dismiss on the follow-up click (not pointerdown) so the
          // tap cannot fall through to the kiosk UI underneath.
          this.activity = event => {
            if (!this.active) {
              this.arm()
            } else if (event.type === "keydown") {
              this.hide()
            }
          }

          this.dismiss = event => {
            if (!this.active) return
            event.preventDefault()
            event.stopPropagation()
            this.hide()
            // Always return the kiosk to the main check-in screen.
            this.pushEvent("info_mode_dismissed", {})
          }

          this.events = ["pointerdown", "keydown", "touchstart", "wheel"]
          this.events.forEach(event =>
            window.addEventListener(event, this.activity, {passive: true, capture: true})
          )
          window.addEventListener("click", this.dismiss, {capture: true})

          // A menu button can show the slideshow on demand.
          this.showHandler = () => this.show()
          this.el.addEventListener("info-mode:show", this.showHandler)

          this.arm()
        },

        arm() {
          clearTimeout(this.idleTimer)
          this.idleTimer = setTimeout(() => this.show(), this.idleMs)
        },

        show() {
          this.slides = Array.from(this.el.querySelectorAll("[data-info-slide]"))
          if (this.slides.length === 0) {
            this.arm()
            return
          }

          this.active = true
          this.index = 0
          this.render()
          this.el.classList.remove("hidden")

          clearInterval(this.rotationTimer)
          if (this.slides.length > 1) {
            this.rotationTimer = setInterval(() => {
              this.index = (this.index + 1) % this.slides.length
              this.render()
            }, this.rotationMs)
          }
        },

        hide() {
          this.active = false
          this.el.classList.add("hidden")
          clearInterval(this.rotationTimer)
          this.arm()
        },

        render() {
          this.slides.forEach((slide, index) =>
            slide.classList.toggle("hidden", index !== this.index)
          )
        },

        destroyed() {
          clearTimeout(this.idleTimer)
          clearInterval(this.rotationTimer)
          this.events.forEach(event =>
            window.removeEventListener(event, this.activity, {capture: true})
          )
          window.removeEventListener("click", this.dismiss, {capture: true})
          this.el.removeEventListener("info-mode:show", this.showHandler)
        }
      }
    </script>
    """
  end
end
