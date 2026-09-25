import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// PATCHes the form, as it stands, to the page it is on. The shadow action runs
// that page's own action, assigns the form to its object and renders its own
// template, which is morphed in so focus, scroll and everything typed survive.
// Inside a frame, only the frame is asked for and morphed, as Turbo would.
//
// Fetched rather than submitted through Turbo: Turbo renders a form response
// only if it redirects or fails, and scrolls to the top when it does.
export default class extends Controller {
  static values = { url: String }

  async perform() {
    const frame = this.#frame
    const busy = [ this.element, frame ].filter(Boolean)
    const headers = { Accept: "text/html" }
    if (frame) headers["Turbo-Frame"] = frame.id

    markAsBusy(busy)
    try {
      const response = await Turbo.fetch(this.urlValue, { method: "PATCH", body: new FormData(this.element), headers })
      const page = new DOMParser().parseFromString(await response.text(), "text/html")

      if (frame) Turbo.morphTurboFrameElements(frame, page.getElementById(frame.id))
      else Turbo.morphBodyElements(document.body, page.body)
    } finally {
      clearBusyState(busy)
    }
    countVisit()
  }

  // Turbo's own targeting: the form's data-turbo-frame, where "_top" means the
  // page, and otherwise the frame the form sits in.
  get #frame() {
    const id = this.element.dataset.turboFrame
    if (id === "_top") return null

    return id ? document.getElementById(id) : this.element.closest("turbo-frame")
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
