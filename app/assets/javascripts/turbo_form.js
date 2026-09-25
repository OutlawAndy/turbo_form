import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Never worth putting in a URL: the token is a secret, and the page's own
// verb is GET whatever the form says.
const UNSENT = new Set(["authenticity_token", "_method"])

// Reloads the page with the form's current state in the query string. The
// page's own action renders it again, and the form assigns that state to its
// object on the way, so the whole page answers as the user now has it. The
// header is what tells the server this is that reload and not an ordinary
// visit to the same URL.
//
// A morphing refresh keeps focus and scroll, so it reads as the form updating
// in place rather than as a navigation.
export default class extends Controller {
  perform() {
    const url = new URL(location.href)
    const data = new FormData(this.element)

    for (const name of new Set(data.keys())) url.searchParams.delete(name)
    for (const [name, value] of data) {
      if (typeof value === "string" && !UNSENT.has(name)) url.searchParams.append(name, value)
    }

    const markReload = ({ detail: { url: requested, fetchOptions } }) => {
      if (requested.href !== url.href) return

      fetchOptions.headers["X-Turbo-Form"] = "reload"
      document.removeEventListener("turbo:before-fetch-request", markReload)
    }

    document.addEventListener("turbo:before-fetch-request", markReload)
    document.addEventListener("turbo:load", countVisit, { once: true })
    Turbo.visit(url, { action: "replace", shouldCacheSnapshot: false, refresh: { method: "morph", scroll: "preserve" } })
  }
}

// Kept on <html> because a morph rewrites <body> to what the server sent, and
// the server never knows the count. Lets a system test wait on a completed
// reload instead of sleeping.
function countVisit() {
  const root = document.documentElement.dataset
  root.turboFormVisits = Number(root.turboFormVisits || 0) + 1
}
