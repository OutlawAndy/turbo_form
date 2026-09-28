import { Turbo } from "@hotwired/turbo-rails"

// PATCHes the form, as it stands, to the page it is on. The server runs that
// page's own action, assigns the form to its object and renders its own
// template, which is morphed in so focus, scroll and everything typed survive.
// Inside a frame, only the frame is asked for and morphed, as Turbo would.
//
// Fetched rather than submitted through Turbo, which renders a form response
// only if it redirects or fails. The page is still rendered by Turbo: a visit
// handed the response, so its events, error page and progress bar all apply. A
// frame is morphed directly, since Turbo's frame loading wants its own
// unexported response object.
export function refresh(form) {
  return new FormRefresh(form).start()
}

// Shaped like Turbo's FormSubmission, which is what its navigator expects to be
// told about.
class FormRefresh {
  constructor(formElement) {
    this.formElement = formElement
    this.location = new URL(formElement.dataset.turboFormUrl, location.href)
    this.target = targetFor(formElement)
  }

  async start() {
    this.requestStarted()
    try {
      const response = await Turbo.fetch(this.location, { method: "PATCH", body: new FormData(this.formElement), headers: { ...this.target.headers, "X-CSRF-Token": csrfToken() } })

      this.target.render(response.status, await response.text())
    } finally {
      this.requestFinished()
    }
  }

  requestStarted() {
    markAsBusy(this.formElement, ...this.target.elements)
    Turbo.navigator.formSubmissionStarted(this)
  }

  requestFinished() {
    clearBusyState(this.formElement, ...this.target.elements)
    Turbo.navigator.formSubmissionFinished(this)
  }
}

class PageTarget {
  elements = []
  headers = { Accept: "text/html" }

  render(statusCode, responseHTML) {
    document.addEventListener("turbo:load", countVisit, { once: true })
    Turbo.visit(location.href, {
      action: "replace",
      shouldCacheSnapshot: false,
      refresh: { method: "morph", scroll: "preserve" },
      response: { statusCode, responseHTML }
    })
  }
}

class FrameTarget {
  constructor(element) {
    this.element = element
    this.elements = [ element ]
  }

  get headers() {
    return { Accept: "text/html", "Turbo-Frame": this.element.id }
  }

  render(_statusCode, responseHTML) {
    const frame = new DOMParser().parseFromString(responseHTML, "text/html").getElementById(this.element.id)

    Turbo.morphTurboFrameElements(this.element, frame)
    countVisit()
  }
}

// Turbo's own targeting: the form's data-turbo-frame, then the target of the
// frame it sits in, then that frame itself. "_top" means the page.
function targetFor(form) {
  const enclosing = form.closest("turbo-frame")
  const id = form.dataset.turboFrame || enclosing?.getAttribute("target")
  const frame = id === "_top" ? null : id ? document.getElementById(id) : enclosing

  return frame ? new FrameTarget(frame) : new PageTarget()
}

// The form's own authenticity token is scoped to its action and method when
// per-form tokens are on, as they are by default, so it can't vouch for this
// PATCH. The page's token can, as it does for Turbo's own submissions.
function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

const triggerSelector = "[data-turbo-form-trigger]"

// Shaped like Turbo's observers. One listener per event the page's triggers
// name, on the event target and in the capture phase, so fields rendered later
// are covered and events that don't bubble, like blur, still arrive. New names
// are picked up as triggers appear; the browser ignores a listener it already has.
class TriggerObserver {
  constructor(delegate, eventTarget) {
    this.delegate = delegate
    this.eventTarget = eventTarget
    this.mutationObserver = new MutationObserver(this.listen)
  }

  start() {
    this.listen()
    this.mutationObserver.observe(this.eventTarget, { subtree: true, childList: true, attributeFilter: [ "data-turbo-form-trigger" ] })
  }

  listen = () => {
    for (const trigger of this.eventTarget.querySelectorAll(triggerSelector)) {
      this.eventTarget.addEventListener(eventFor(trigger), this.triggerCaptured, true)
    }
  }

  triggerCaptured = ({ type, target }) => {
    const trigger = target.closest?.(triggerSelector)
    const form = trigger?.form

    if (form?.dataset.turboFormUrl && eventFor(trigger) == type) this.delegate.triggerFired(form)
  }
}

// A trigger with no event named fires on its element's natural one.
function eventFor(trigger) {
  const named = trigger.dataset.turboFormTrigger
  if (named) return named
  if (trigger.localName == "select") return "change"
  if (trigger.type == "submit") return "click"

  return "input"
}

// Turbo's own busy state, which it doesn't export.
function markAsBusy(...elements) {
  for (const element of elements) {
    if (element.localName == "turbo-frame") element.setAttribute("busy", "")
    element.setAttribute("aria-busy", "true")
  }
}

function clearBusyState(...elements) {
  for (const element of elements) {
    if (element.localName == "turbo-frame") element.removeAttribute("busy")
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

new TriggerObserver({ triggerFired: refresh }, document).start()
