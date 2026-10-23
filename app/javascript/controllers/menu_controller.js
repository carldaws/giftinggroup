import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.closeWhenOutside = this.closeWhenOutside.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)
    document.addEventListener("click", this.closeWhenOutside)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("click", this.closeWhenOutside)
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  toggled() {
    if (this.element.open) {
      document.querySelectorAll("details[data-controller~=menu][open]").forEach(menu => {
        if (menu !== this.element) menu.open = false
      })
    }
  }

  closeWhenOutside(event) {
    if (!this.element.contains(event.target)) this.element.open = false
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.element.open) {
      this.element.open = false
      this.element.querySelector("summary").focus()
    }
  }
}
