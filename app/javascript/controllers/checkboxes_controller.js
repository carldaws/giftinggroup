import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkbox", "toggle" ]
  static values = { selectAll: String, clearAll: String }

  connect() {
    this.update()
  }

  toggleAll() {
    const checked = !this.allChecked
    this.checkboxTargets.forEach(checkbox => checkbox.checked = checked)
    this.update()
  }

  update() {
    this.toggleTarget.textContent = this.allChecked ? this.clearAllValue : this.selectAllValue
  }

  get allChecked() {
    return this.checkboxTargets.every(checkbox => checkbox.checked)
  }
}
