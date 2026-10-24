import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "url", "name", "preview", "image", "photo", "status" ]
  static values = { endpoint: String }

  typed(event) {
    if (event.inputType === "insertFromPaste") this.look()
  }

  look() {
    const url = this.urlTarget.value.trim()
    if (url === this.currentUrl) return

    this.currentUrl = url
    this.request?.abort()
    this.#showPhoto(null)
    if (url !== "" && this.urlTarget.checkValidity()) this.#fetch(url)
  }

  async #fetch(url) {
    const request = this.request = new AbortController()
    this.statusTarget.hidden = false

    try {
      const response = await fetch(this.endpointValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": this.#csrfToken },
        body: JSON.stringify({ url }),
        signal: request.signal
      })
      const preview = response.ok ? await response.json() : {}
      if (request === this.request) this.#fill(preview)
    } catch (error) {
      if (error.name !== "AbortError") this.currentUrl = null
    } finally {
      if (request === this.request) this.statusTarget.hidden = true
    }
  }

  #fill({ title, photo }) {
    const name = this.nameTarget.value.trim()

    if (title && (name === "" || name === this.filledTitle)) {
      this.nameTarget.value = title
      this.filledTitle = title
    }
    this.#showPhoto(photo)
  }

  #showPhoto(photo) {
    this.previewTarget.hidden = !photo
    this.photoTarget.disabled = !photo
    this.photoTarget.checked = Boolean(photo)
    this.photoTarget.value = photo ? photo.signed_id : ""

    if (photo) {
      this.imageTarget.src = photo.url
    } else {
      this.imageTarget.removeAttribute("src")
    }
  }

  get #csrfToken() {
    return document.querySelector("meta[name=csrf-token]").content
  }
}
