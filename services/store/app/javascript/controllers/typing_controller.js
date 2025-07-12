// typing_controller.js
import { Controller } from "@hotwired/stimulus"

// Sends startTyping / stopTyping signals to backend so that WAHA can
// broadcast typing presence to the other participant.
//
// Expects data-chat-id and data-session on the element with this controller.
export default class extends Controller {
  static values = {
    chatId: String,
    session: String,
    url: String
  }

  connect() {
    this.timer = null
  }

  start() {
    // Called on input event (debounced by 300ms)
    if (!this.typing) {
      this.sendTyping("start")
      this.typing = true
    }

    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      this.stop()
    }, 3000)
  }

  stop() {
    if (!this.typing) return
    this.typing = false
    this.sendTyping("stop")
  }

  sendTyping(kind) {
    const url = this.urlValue || `/chats/${this.chatIdValue}/typing${kind === "stop" ? "/stop" : ""}`
    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({})
    })
  }
}