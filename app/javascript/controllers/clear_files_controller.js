import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input" ]

  clear(event) {
    if (!event.detail.success) this.inputTargets.forEach(input => input.value = "")
  }
}
