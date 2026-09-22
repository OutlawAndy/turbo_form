import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Re-renders the form it is attached to, from the server, as a Turbo Stream.
//
// The whole form is submitted so the server sees exactly the state the user is
// looking at; nothing is saved, and the response only describes what should
// change on screen.
export default class extends Controller {
  static values = { url: String, requests: Number }

  // A trigger can send the form somewhere other than the form's own endpoint,
  // and can add to what it sends. Both ride in as Stimulus action params, so
  // one form can feed several actions without needing several forms.
  async perform({ params: { url, query } }) {
    const body = new FormData(this.element)

    if (query) Object.entries(query).forEach(([name, value]) => body.append(name, value))

    const response = await fetch(url || this.urlValue, {
      method: "PATCH",
      headers: this.#headers,
      body
    })

    if (!response.ok) return

    Turbo.renderStreamMessage(await response.text())

    // Lets a system test wait on a completed round trip instead of sleeping.
    this.requestsValue++
  }

  get #headers() {
    const headers = { Accept: "text/vnd.turbo-stream.html" }
    const token = document.querySelector("meta[name=csrf-token]")?.content

    // The form's own authenticity_token rides along in the body; this covers
    // the forms that don't carry one.
    if (token) headers["X-CSRF-Token"] = token

    return headers
  }
}
