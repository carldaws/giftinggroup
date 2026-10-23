import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "button" ]
  static values = { show: String, hide: String }

  toggle() {
    const revealing = this.inputTarget.type === "password"
    this.inputTarget.type = revealing ? "text" : "password"
    this.buttonTarget.textContent = revealing ? this.hideValue : this.showValue
    this.buttonTarget.setAttribute("aria-pressed", revealing)
  }
}
