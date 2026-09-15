import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Re-renders the form it is attached to, from the server, as a Turbo Stream.
//
// The whole form is submitted so the server sees exactly the state the user is
// looking at; nothing is saved, and the response only describes what should
// change on screen.
export default class extends Controller {
  static values = { url: String, requests: Number }

  async submit() {
    const response = await fetch(this.urlValue, {
      method: "PATCH",
      headers: this.#headers,
      body: new FormData(this.element)
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
