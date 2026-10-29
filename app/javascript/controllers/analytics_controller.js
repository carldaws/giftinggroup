import { Controller } from "@hotwired/stimulus"

let unsentReferrer = outsideReferrer()

export default class extends Controller {
  static values = { url: String, payload: Object, once: Boolean }

  connect() {
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    fetch(this.urlValue, {
      method: "POST",
      keepalive: true,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ type: "event", payload: { ...this.payloadValue, ...browser(), referrer: takeReferrer() } })
    }).catch(() => {})

    if (this.onceValue) this.element.remove()
  }

}

function browser() {
  return {
    hostname: location.hostname,
    language: navigator.language,
    screen: `${screen.width}x${screen.height}`
  }
}

function outsideReferrer() {
  const origin = document.referrer && new URL(document.referrer).origin
  return origin === location.origin ? "" : origin
}

function takeReferrer() {
  const referrer = unsentReferrer
  unsentReferrer = ""
  return referrer
}
