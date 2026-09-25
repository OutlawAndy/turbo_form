import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// PATCHes the form, as it stands, to the page it is on. The shadow action runs
// that page's own action, assigns the form to its object and renders its own
// template, which is morphed in so focus, scroll and everything typed survive.
// Inside a frame, only the frame is asked for and morphed, as Turbo would.
//
// Fetched rather than submitted through Turbo, which renders a form response
// only if it redirects or fails. The page is still rendered by Turbo: a visit
// handed the response, so its events, error page and progress bar all apply. A
// frame is morphed directly, since Turbo's frame loading wants its own
// unexported response object.
export default class extends Controller {
  static values = { url: String }

  async perform() {
    const frame = this.#frame
    const submission = { formElement: this.element, location: new URL(this.urlValue, location.href) }

    this.#markBusy(frame)
    Turbo.navigator.formSubmissionStarted(submission)
    try {
      const response = await this.#fetch(frame)
      const html = await response.text()

      frame ? this.#morph(frame, html) : this.#visit(response.status, html)
    } finally {
      this.#clearBusy(frame)
      Turbo.navigator.formSubmissionFinished(submission)
    }
  }

  // Private

  #fetch(frame) {
    const headers = { Accept: "text/html" }
    if (frame) headers["Turbo-Frame"] = frame.id

    return Turbo.fetch(this.urlValue, { method: "PATCH", body: new FormData(this.element), headers })
  }

  #morph(frame, html) {
    Turbo.morphTurboFrameElements(frame, new DOMParser().parseFromString(html, "text/html").getElementById(frame.id))
    this.#countVisit()
  }

  #visit(statusCode, responseHTML) {
    document.addEventListener("turbo:load", () => this.#countVisit(), { once: true })
    Turbo.visit(location.href, {
      action: "replace",
      shouldCacheSnapshot: false,
      refresh: { method: "morph", scroll: "preserve" },
      response: { statusCode, responseHTML }
    })
  }

  // Turbo's own targeting: the form's data-turbo-frame, then the target of the
  // frame it sits in, then that frame itself. "_top" means the page.
  get #frame() {
    const enclosing = this.element.closest("turbo-frame")
    const id = this.element.dataset.turboFrame || enclosing?.getAttribute("target")
    if (id === "_top") return null

    return id ? document.getElementById(id) : enclosing
  }

  // Turbo's own busy state for a submission, which it doesn't export: `busy` on
  // a frame, `aria-busy` on everything.
  #markBusy(frame) {
    frame?.setAttribute("busy", "")
    for (const element of [ this.element, frame ].filter(Boolean)) element.setAttribute("aria-busy", "true")
  }

  #clearBusy(frame) {
    frame?.removeAttribute("busy")
    for (const element of [ this.element, frame ].filter(Boolean)) element.removeAttribute("aria-busy")
  }

  // Kept on <html> because a morph rewrites <body> to what the server sent, and
  // the server never knows the count. Lets a system test wait on a completed
  // reload instead of sleeping.
  #countVisit() {
    const root = document.documentElement.dataset
    root.turboFormVisits = Number(root.turboFormVisits || 0) + 1
  }
}
