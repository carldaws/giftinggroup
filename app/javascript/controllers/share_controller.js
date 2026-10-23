import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "shareButton", "copyButton" ]
  static values = { url: String, title: String, copied: String }

  connect() {
    if (navigator.share) this.shareButtonTarget.hidden = false
  }

  async share() {
    try {
      await navigator.share({ title: this.titleValue, url: this.urlValue })
    } catch (error) {
      if (error.name !== "AbortError") this.copy()
    }
  }

  async copy() {
    await navigator.clipboard.writeText(this.urlValue)

    const label = this.copyButtonTarget.textContent
    this.copyButtonTarget.textContent = this.copiedValue
    setTimeout(() => this.copyButtonTarget.textContent = label, 2000)
  }
}
