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
//
// A trigger naming a URL of its own, with data-turbo-form-action, PATCHes the
// form there instead and renders the Turbo Stream that comes back.
export function refresh(form, trigger) {
  return new FormRefresh(form, trigger).start()
}

// Shaped like Turbo's FormSubmission, which is what its navigator expects to be
// told about.
class FormRefresh {
  constructor(formElement, trigger) {
    const action = trigger?.dataset.turboFormAction

    this.formElement = formElement
    this.location = new URL(action || formElement.dataset.turboFormUrl, location.href)
    this.target = action ? new StreamTarget() : targetFor(formElement)
  }

  async start() {
    this.requestStarted()
    try {
      const response = await Turbo.fetch(this.location, { method: "PATCH", body: new FormData(this.formElement), headers: { ...this.target.headers, "X-CSRF-Token": csrfToken() } })

      if (!this.superseded) await this.target.render(response)
    } finally {
      this.requestFinished()
    }
  }

  requestStarted() {
    latestRefreshes(this.formElement).set(this.location.href, this)
    markAsBusy(this.formElement, ...this.target.elements)
    Turbo.navigator.formSubmissionStarted(this)
  }

  requestFinished() {
    if (!this.superseded) clearBusyState(this.formElement, ...this.target.elements)
    Turbo.navigator.formSubmissionFinished(this)
  }

  // Responses can arrive out of order. Only the last one sent to a URL is
  // rendered, so the page ends up answering the form as it was last sent.
  get superseded() {
    return latestRefreshes(this.formElement).get(this.location.href) != this
  }
}

const refreshes = new WeakMap()

function latestRefreshes(form) {
  return refreshes.get(form) ?? refreshes.set(form, new Map).get(form)
}

class PageTarget {
  elements = []
  headers = { Accept: "text/html" }

  async render(response) {
    const responseHTML = await response.text()

    document.addEventListener("turbo:load", countVisit, { once: true })
    Turbo.visit(location.href, {
      action: "replace",
      shouldCacheSnapshot: false,
      refresh: { method: "morph", scroll: "preserve" },
      response: { statusCode: response.status, responseHTML }
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

  async render(response) {
    const frame = new DOMParser().parseFromString(await response.text(), "text/html").getElementById(this.element.id)

    Turbo.morphTurboFrameElements(this.element, frame)
    countVisit()
  }
}

const streamType = "text/vnd.turbo-stream.html"

// Whatever the status, as Turbo does for a form: a 422 stream of errors is
// rendered too. Anything else, like an HTML error page, isn't a stream to render.
class StreamTarget {
  elements = []
  headers = { Accept: streamType }

  async render(response) {
    if (!response.headers.get("Content-Type")?.startsWith(streamType)) return

    Turbo.renderStreamMessage(await response.text())
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

    if (form && (trigger.dataset.turboFormAction || form.dataset.turboFormUrl) && eventFor(trigger) == type) debounce(trigger, type, () => this.delegate.triggerFired(form, trigger))
  }
}

const timers = new WeakMap()

// An input event, fired on every keystroke, waits for a 300ms pause before
// sending the form as it stands by then. data-turbo-form-debounce names a wait
// of its own for any event, or 0 for none. A trigger gone from the page by then,
// as when the user has moved on, sends nothing.
function debounce(trigger, type, fire) {
  const wait = Number(trigger.dataset.turboFormDebounce ?? (type == "input" ? 300 : 0))
  if (!wait) return fire()

  clearTimeout(timers.get(trigger))
  timers.set(trigger, setTimeout(() => trigger.isConnected && fire(), wait))
}

// A trigger with no event named fires on its element's natural one.
function eventFor(trigger) {
  const named = trigger.dataset.turboFormTrigger
  if (named) return named
  if (trigger.localName == "select") return "change"
  if (trigger.type == "submit" || trigger.type == "button") return "click"

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

// A response answers the form as it was sent, which may be a keystroke or more
// behind the field being typed into. That field keeps what it has.
function keepFocusedValue(event) {
  const { target, detail } = event

  if (target == document.activeElement && target.form?.querySelector(triggerSelector) && detail.attributeName == "value") event.preventDefault()
}

new TriggerObserver({ triggerFired: refresh }, document).start()
addEventListener("turbo:before-morph-attribute", keepFocusedValue)
