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
    const busy = [ this.element, frame ].filter(Boolean)
    const headers = { Accept: "text/html" }
    if (frame) headers["Turbo-Frame"] = frame.id

    const submission = { formElement: this.element, location: new URL(this.urlValue, location.href) }

    markAsBusy(busy)
    Turbo.navigator.formSubmissionStarted(submission)
    try {
      const response = await Turbo.fetch(this.urlValue, { method: "PATCH", body: new FormData(this.element), headers })
      const responseHTML = await response.text()

      if (frame) {
        Turbo.morphTurboFrameElements(frame, new DOMParser().parseFromString(responseHTML, "text/html").getElementById(frame.id))
        countVisit()
      } else {
        document.addEventListener("turbo:load", countVisit, { once: true })
        Turbo.visit(location.href, { action: "replace", shouldCacheSnapshot: false, refresh: { method: "morph", scroll: "preserve" }, response: { statusCode: response.status, responseHTML } })
      }
    } finally {
      clearBusyState(busy)
      Turbo.navigator.formSubmissionFinished(submission)
    }
  }

  // Turbo's own targeting: the form's data-turbo-frame, then the target of the
  // frame it sits in, then that frame itself. "_top" means the page.
  get #frame() {
    const enclosing = this.element.closest("turbo-frame")
    const id = this.element.dataset.turboFrame || enclosing?.getAttribute("target")
    if (id === "_top") return null

    return id ? document.getElementById(id) : enclosing
  }
}

// Turbo's own busy state for a submission, which it doesn't export: `busy` on a
// frame, `aria-busy` on everything.
function markAsBusy(elements) {
  for (const element of elements) {
    if (element.localName == "turbo-frame") element.setAttribute("busy", "")
    element.setAttribute("aria-busy", "true")
  }
}

function clearBusyState(elements) {
  for (const element of elements) {
    element.removeAttribute("busy")
    element.removeAttribute("aria-busy")
  }
}

// Kept on <html> because a morph rewrites <body> to what the server sent, and
// the server never knows the count. Lets a system test wait on a completed
// reload instead of sleeping.
function countVisit() {
  const root = document.documentElement.dataset
  root.turboFormVisits = Number(root.turboFormVisits || 0) + 1
}
