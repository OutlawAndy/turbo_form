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
export async function refresh(form) {
  const url = form.dataset.turboFormUrl
  const frame = frameFor(form)
  const busy = [ form, frame ].filter(Boolean)
  const submission = { formElement: form, location: new URL(url, location.href) }

  markBusy(busy, frame)
  Turbo.navigator.formSubmissionStarted(submission)
  try {
    const response = await Turbo.fetch(url, { method: "PATCH", body: new FormData(form), headers: headersFor(frame) })
    const html = await response.text()

    frame ? morph(frame, html) : visit(response.status, html)
  } finally {
    clearBusy(busy, frame)
    Turbo.navigator.formSubmissionFinished(submission)
  }
}

// One listener per event the page's triggers name, on the document and in the
// capture phase, so fields rendered later are covered and events that don't
// bubble, like blur, still arrive. New names are picked up as triggers appear.
const listening = new Set()

function listenForTriggers() {
  for (const trigger of document.querySelectorAll("[data-turbo-form-trigger]")) {
    const type = eventFor(trigger)
    if (listening.has(type)) continue

    listening.add(type)
    document.addEventListener(type, handleTrigger, true)
  }
}

function handleTrigger({ type, target }) {
  const trigger = target.closest?.("[data-turbo-form-trigger]")
  if (trigger?.form?.dataset.turboFormUrl && eventFor(trigger) == type) refresh(trigger.form)
}

listenForTriggers()
new MutationObserver(listenForTriggers).observe(document, { subtree: true, childList: true, attributeFilter: [ "data-turbo-form-trigger" ] })

// A trigger with no event named fires on its element's natural one.
function eventFor(trigger) {
  const named = trigger.dataset.turboFormTrigger
  if (named) return named
  if (trigger.localName == "select") return "change"
  if (trigger.type == "submit") return "click"

  return "input"
}

function headersFor(frame) {
  const headers = { Accept: "text/html" }
  if (frame) headers["Turbo-Frame"] = frame.id

  return headers
}

function morph(frame, html) {
  Turbo.morphTurboFrameElements(frame, new DOMParser().parseFromString(html, "text/html").getElementById(frame.id))
  countVisit()
}

function visit(statusCode, responseHTML) {
  document.addEventListener("turbo:load", countVisit, { once: true })
  Turbo.visit(location.href, {
    action: "replace",
    shouldCacheSnapshot: false,
    refresh: { method: "morph", scroll: "preserve" },
    response: { statusCode, responseHTML }
  })
}

// Turbo's own targeting: the form's data-turbo-frame, then the target of the
// frame it sits in, then that frame itself. "_top" means the page.
function frameFor(form) {
  const enclosing = form.closest("turbo-frame")
  const id = form.dataset.turboFrame || enclosing?.getAttribute("target")
  if (id === "_top") return null

  return id ? document.getElementById(id) : enclosing
}

// Turbo's own busy state for a submission, which it doesn't export: `busy` on
// a frame, `aria-busy` on everything.
function markBusy(elements, frame) {
  frame?.setAttribute("busy", "")
  for (const element of elements) element.setAttribute("aria-busy", "true")
}

function clearBusy(elements, frame) {
  frame?.removeAttribute("busy")
  for (const element of elements) element.removeAttribute("aria-busy")
}

// Kept on <html> because a morph rewrites <body> to what the server sent, and
// the server never knows the count. Lets a system test wait on a completed
// reload instead of sleeping.
function countVisit() {
  const root = document.documentElement.dataset
  root.turboFormVisits = Number(root.turboFormVisits || 0) + 1
}
